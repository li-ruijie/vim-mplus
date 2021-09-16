@ECHO OFF
git add -A
git commit -m "updated"
git push
vim "+PlugUpdate vim-mplus" +qall
