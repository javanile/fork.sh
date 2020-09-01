# FORK.SH


## Installation

```
## with cURL and BASH
curl -sL git.io/fork.sh | bash -
```

```
## with Dorker for Linux/macOS
docker run --rm -ti -v "$PWD:/app" javanile/fork.sh
```

```
## with Dorker for Windows
docker run --rm -ti -v "%CD%:/app" javanile/fork.sh
```

## Usage

### Forkfile magic variables

-  `Forkfile_name`  


## Shorturl

```bash
curl -i "https://git.io" \
     -d "url=https://raw.githubusercontent.com/javanile/fork.sh/master/fork.sh" \
     -d "code=fork.sh"
```
