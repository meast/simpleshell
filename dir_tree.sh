find . -maxdepth 3 -print |sed -e 's;[^/]*/;|____;g;s;____|; |;g'
