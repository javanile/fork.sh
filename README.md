# FORK.SH


## Get started

```
## with cURL and BASH
curl -sL git.io/fork.sh | bash -
```

```
## with Dorker for Linux/macOS
docker run --rm -v $PWD:/app -ti javanile/fork.sh
```

```
## with Dorker for Windows
docker run --rm -v %cd%:/app -ti javanile/fork.sh
```

## Url shortening

```bash
curl -i https://git.io \
     -F "url=https://raw.githubusercontent.com/javanile/fork.sh/master/fork.sh" \
     -F "code=fork.sh"
```
