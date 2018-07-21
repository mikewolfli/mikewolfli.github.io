@echo off
call hexo generate
cd public
git add -u
git commit -m ¡°update¡±

git push origin master

cd ..

