"""Make a corpus of Mplus outputs for the tests of the output syntax. Called by make-corpus.sh.

Two sets of runs are made, each input in a directory of its own below the cache directory.

  all-options  every example input with its OUTPUT command replaced by every option that Mplus
               9.1.1 takes, so that the outputs show the parts that the shipped outputs lack
  failures     the inputs of test/corpus/failures/, which make Mplus print the messages of a
               failed or doubtful estimation and of bad input

An option that the analysis does not take gives a warning, and Mplus goes on. Where Mplus stops
at an option instead, with an error in the OUTPUT command that ignores nothing, the input is run
again without that option. So is an input whose run was over the time limit with TECH14, without
TECH14. The run before is kept under the name <stem>-try<n>.

An input whose record (run.json) is in its directory has been run and is not run again. The
manifest (manifest.tsv, one line for each run of Mplus) is written at the end. When every input
of both sets has a record, and no --only was given, the empty file DONE is written as well.
"""
import argparse
import contextlib
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent

# The section rule of autoload/mplus/section.vim. A command name in full or shortened to four or
# more letters, then a colon at once or after one more word.
NAMES = (r"TITL(?:E)?|DATA|VARI(?:A(?:B(?:L(?:E)?)?)?)?|DEFI(?:N(?:E)?)?|ANAL(?:Y(?:S(?:I(?:S)?)?)?)?"
         r"|MODE(?:L)?|OUTP(?:U(?:T)?)?|SAVE(?:D(?:A(?:T(?:A)?)?)?)?|PLOT"
         r"|MONT(?:E(?:C(?:A(?:R(?:L(?:O)?)?)?)?)?)?")
HEADER = re.compile(rf"\s*({NAMES})(\s+[^:\s]+)?\s*:", re.IGNORECASE)

# The OUTPUT options of Mplus 9.1.1, from chapter 18 of the user's guide and from the keyword
# table in mplus.exe. NOCHISQUARE, NOSERROR, NOCFI, and NOSVALUES are left out, since they take
# parts away from the output. Each setting in braces is filled in by output_options().
OPTIONS = ("SAMPSTAT CROSSTABS (ALL) STANDARDIZED{cluster} RESIDUAL{cluster} MODINDICES (ALL 0)"
           " CINTERVAL{interval} SVALUES H1SE H1TECH3 H1MODEL PATTERNS ENTROPY FSCOEFFICIENT"
           " FSDETERMINACY FSCOMPARISON BASEHAZARD LOGRANK ALIGNMENT ODDSRATIO DELETEDRECORDS"
           " FULLOUTPUT KOLMOGOROV SERROR TECH1 TECH2 TECH3 TECH4{cluster} TECH5 TECH6 TECH7 TECH8"
           " TECH9 TECH10 TECH11 TECH12 TECH13 TECH14 TECH15 TECH16")
OPTION = re.compile(r"\S+(?: \([^)]*\))?")
SETTING = r"\s*(?:=|\bIS\b|\bARE\b)\s*"
BAYES = re.compile(rf"\bESTI\w*{SETTING}BAYE", re.IGNORECASE)
BOOTSTRAP = re.compile(rf"\bBOOT\w*{SETTING}\d", re.IGNORECASE)
TWOLEVEL = re.compile(rf"\bTYPE{SETTING}[^;]*\bTWOLEVEL\b", re.IGNORECASE)
# An error in the OUTPUT command and the indented lines of its message.
OUTPUT_ERROR = re.compile(r"^\*\*\* ERROR in OUTPUT command\n((?:[ \t]+\S.*\n)+)", re.MULTILINE)


def natural(text: str):
    """Key that sorts ex3.2 before ex3.10."""
    return [int(part) if part.isdigit() else part.lower() for part in re.split(r"(\d+)", text)]


def lines_of(text: str) -> list:
    lines = re.split(r"\r?\n", text)
    return lines[:-1] if lines and lines[-1] == "" else lines


def output_command(lines: list):
    """The first and the next to last line of the OUTPUT command of an input, which runs from its
    header to the next section header. Both are the end of the input when it has none."""
    start = end = None
    for number, line in enumerate(lines):
        match = HEADER.match(line)
        if match and start is not None and end is None:
            end = number
        if match and start is None and match.group(1).upper().startswith("OUTP") \
                and not match.group(2):
            start = number
    if start is None:
        return len(lines), len(lines)
    return start, len(lines) if end is None else end


def output_options(lines: list, dropped: list) -> list:
    """The OUTPUT options for an input, without the options named in dropped.

    CINTERVAL takes one setting. It is BCBOOTSTRAP for an analysis with bootstrap draws and HPD
    for a Bayesian one. The CLUSTER settings are for TYPE=TWOLEVEL with ESTIMATOR=BAYES.
    """
    start, end = output_command(lines)
    code = "\n".join(line.split("!")[0] for line in lines[:start] + lines[end:])
    bayes = bool(BAYES.search(code))
    interval = " (BCBOOTSTRAP)" if BOOTSTRAP.search(code) else " (HPD)" if bayes else ""
    cluster = " (CLUSTER)" if bayes and TWOLEVEL.search(code) else ""
    options = OPTION.findall(OPTIONS.format(interval=interval, cluster=cluster))
    return [option for option in options if option.split()[0] not in dropped]


def with_options(lines: list, options: list) -> str:
    """The input with its OUTPUT command replaced by one with the options, on lines of at most
    72 characters. An input without an OUTPUT command gets it at its end."""
    block, line = ["OUTPUT:"], ""
    for option in options[:-1] + [options[-1] + ";"]:
        if line and len(line) + 1 + len(option) > 70:
            block.append("  " + line)
            line = option
        else:
            line = f"{line} {option}".strip()
    block.append("  " + line)
    start, end = output_command(lines)
    return "\r\n".join(lines[:start] + block + lines[end:]) + "\r\n"


def to_drop(record: dict, output: Path, options: list):
    """The option to leave out of the next run of an input, or None.

    That is the option at which Mplus stopped in the OUTPUT command. A message that ends in "is
    ignored" or "will be ignored" did not stop Mplus. After a run that was over the time limit it
    is TECH14, unless Mplus ignored it, since its bootstrap draws estimate the model many times.
    """
    names = {option.split()[0] for option in options}
    if not output.exists():
        return None
    text = output.read_bytes().decode("latin-1").replace("\r\n", "\n")
    if record["timeout"]:
        return "TECH14" if "TECH14" in names and "Request for TECH14" not in text else None
    if record["exit"] != 1:
        return None
    for match in OUTPUT_ERROR.finditer(text):
        message = match.group(1)
        if re.search(r"\bignored\b", message):
            continue
        remove = re.search(r"Remove the (\S+) option", message)
        for word in [remove.group(1)] if remove else re.findall(r"[A-Z][A-Z0-9]+", message):
            if word in names:
                return word
    return None


def stage_data(source: Path, run_dir: Path, text: str):
    """Copy into run_dir each file beside source that the input names, or that a file already
    copied names, as the list of the data sets of a Monte Carlo study does."""
    names = {path.name.lower(): path for path in source.parent.iterdir()
             if path.is_file() and path.suffix.lower() not in (".inp", ".out")}
    pending = [text.lower()]
    while pending:
        named = pending.pop()
        for low in [low for low in names if low in named]:
            path = names.pop(low)
            shutil.copyfile(path, run_dir / path.name)
            pending.append(path.read_bytes().decode("latin-1").lower())


class Job:
    def __init__(self, kind: str, source: Path, label: str, cache: Path, place: Path, stem: str):
        self.kind, self.source, self.label = kind, source, label
        self.place, self.stem = place, stem
        self.run_dir = cache / place
        self.input = self.run_dir / f"{stem}.inp"
        self.output = self.run_dir / f"{stem}.out"
        self.record = self.run_dir / "run.json"


def jobs(examples: Path, cache: Path, wanted: str):
    found = []
    for path in sorted(examples.rglob("*.inp"), key=lambda p: natural(str(p.relative_to(examples)))):
        relative = path.relative_to(examples)
        # The input is named apart from the example, as a time limit of another script ends
        # every Mplus process whose command line holds the name of an example.
        found.append(Job("all-options", path, relative.as_posix(), cache,
                         Path("all-options", relative.parent, path.stem), path.stem + "-all"))
    for path in sorted((HERE / "failures").glob("*.inp"), key=lambda p: natural(p.name)):
        found.append(Job("failures", path, path.name, cache, Path("failures", path.stem), path.stem))
    return [job for job in found if re.search(wanted, f"{job.kind}/{job.label}")]


def end_mplus(process: subprocess.Popen, image: str, input_path: Path):
    """End the run of input_path. An analysis with PROCESSORS = 2 starts further Mplus processes
    that are no children of the first one on Windows. Their command lines hold the full path of
    the input, so every process of the Mplus image with that path is ended."""
    if os.name == "nt":
        script = ("Get-CimInstance Win32_Process -Filter \"Name='$env:CORPUS_IMAGE'\" | Where-Object"
                  " { $_.CommandLine -and $_.CommandLine.ToLower().Contains($env:CORPUS_INPUT) } |"
                  " ForEach-Object { Stop-Process -Id $_.ProcessId -Force }")
        env = dict(os.environ, CORPUS_IMAGE=image, CORPUS_INPUT=str(input_path).lower())
        subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command", script],
                       env=env, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW,
                       check=False)
    else:
        with contextlib.suppress(ProcessLookupError):
            os.killpg(process.pid, signal.SIGKILL)
    process.kill()


def run_mplus(job: Job, mplus: str, limit: float, options: list) -> dict:
    """Run Mplus once on the input of job and return the record of the run. Mplus is given the
    full path of the input, and its scratch files go to a directory tmp in the run directory,
    which is removed when Mplus leaves it empty."""
    if job.output.exists():
        job.output.unlink()
    tmp = job.run_dir / "tmp"
    tmp.mkdir(exist_ok=True)
    env = dict(os.environ, TMP=str(tmp), TEMP=str(tmp), FORT_TMPDIR=str(tmp), TMPDIR=str(tmp))
    record = {"set": job.kind, "source": job.label, "output": "", "options": " ".join(options),
              "exit": "", "seconds": 0.0, "timeout": False, "started": True, "lines": 0}
    start = time.monotonic()
    try:
        process = subprocess.Popen(
            [mplus, str(job.input)], cwd=job.run_dir, env=env, stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
            start_new_session=os.name != "nt")
    except OSError as error:
        record.update(started=False, exit=str(error))
    else:
        try:
            record["exit"] = process.wait(timeout=limit)
        except subprocess.TimeoutExpired:
            end_mplus(process, Path(mplus).name, job.input)
            record["exit"] = process.wait()
            record["timeout"] = True
    record["seconds"] = round(time.monotonic() - start, 1)
    if job.output.exists():
        record["output"] = (job.place / job.output.name).as_posix()
        record["lines"] = job.output.read_bytes().count(b"\n")
    if not any(tmp.iterdir()):
        tmp.rmdir()
    return record


def run(job: Job, mplus: str, limit: float) -> list:
    """Run the input of job, again without each option at which Mplus stops, and write the
    records of the runs to run.json."""
    job.run_dir.mkdir(parents=True, exist_ok=True)
    text = job.source.read_bytes().decode("latin-1")
    stage_data(job.source, job.run_dir, text)
    lines, dropped, records = lines_of(text), [], []
    while True:
        options = output_options(lines, dropped) if job.kind == "all-options" else []
        job.input.write_bytes((with_options(lines, options) if options
                               else "\r\n".join(lines) + "\r\n").encode("latin-1"))
        record = run_mplus(job, mplus, limit, options)
        records.append(record)
        drop = to_drop(record, job.output, options) if options else None
        if not drop:
            break
        dropped.append(drop)
        tried = f"{job.stem}-try{len(records)}"
        os.replace(job.input, job.run_dir / f"{tried}.inp")
        os.replace(job.output, job.run_dir / f"{tried}.out")
        record["output"] = (job.place / f"{tried}.out").as_posix()
        record["dropped"] = drop
    part = job.record.with_name("run.json.part")
    part.write_text(json.dumps(records, indent=1), encoding="utf-8")
    os.replace(part, job.record)
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("cache", type=Path, help="directory of the corpus, made when missing")
    parser.add_argument("--mplus", required=True, help="the Mplus executable")
    parser.add_argument("--examples", type=Path, required=True, help="the Mplus examples")
    parser.add_argument("--time-limit", type=float, default=60, help="seconds for one run")
    parser.add_argument("--jobs", type=int, default=3, help="runs side by side")
    parser.add_argument("--only", default="", help="run only the inputs whose set/input matches")
    args = parser.parse_args()
    cache = args.cache.resolve()
    cache.mkdir(parents=True, exist_ok=True)
    done = cache / "DONE"
    if done.exists():
        done.unlink()
    every = jobs(args.examples.resolve(), cache, "")
    todo = [job for job in jobs(args.examples.resolve(), cache, args.only) if not job.record.exists()]
    print(f"{len(every)} inputs, {len(todo)} to run, {args.jobs} side by side, "
          f"limit {args.time_limit:g} s", flush=True)

    def one(job):
        try:
            records = run(job, args.mplus, args.time_limit)
        except OSError as error:
            print(f"{job.kind}/{job.label}: not run, {error}", flush=True)
            return
        for record in records:
            state = "timeout" if record["timeout"] else f"exit {record['exit']}"
            print(f"{record['output'] or job.label}: {state}, {record['seconds']} s, "
                  f"{record['lines']} lines", flush=True)

    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        list(pool.map(one, todo))

    made = [job for job in every if job.record.exists()]
    columns = ("set", "source", "output", "options", "exit", "seconds", "timeout", "started",
               "lines", "dropped")
    with open(cache / "manifest.tsv", "w", encoding="utf-8", newline="\n") as manifest:
        manifest.write("\t".join(columns) + "\n")
        for job in made:
            for record in json.loads(job.record.read_text(encoding="utf-8")):
                manifest.write("\t".join(str(record.get(column, "")) for column in columns) + "\n")
    print(f"manifest: {len(made)} of {len(every)} inputs run", flush=True)
    if len(made) == len(every) and not args.only:
        done.touch()
        print(f"written: {done}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
