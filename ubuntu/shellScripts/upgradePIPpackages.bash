 python3 -m pip list --outdated | grep -v '\[' | awk '{print $1}' | xargs -n1 python3 -m pip install --upgrade 