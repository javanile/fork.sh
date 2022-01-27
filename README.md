# FORK.SH


## Installation

#### Linux

```
## Fork soft with cURL and BASH
curl -sL git.io/fork.sh | bash -
```

```
## Fork hard with cURL and BASH
curl -sL git.io/fork.sh | bash -s -- --hard
```

```
## with Dorker for Linux/macOS
docker run --rm -ti -v "$PWD:/app" javanile/fork.sh
```

```
## with Dorker for Linux/macOS
docker run --rm -ti -v "$PWD:/app" javanile/fork.sh --hard
```


```
## with Dorker for Windows
docker run --rm -ti -v "%CD%:/app" javanile/fork.sh
```

```
## with Dorker for Windows
docker run --rm -ti -v "%CD%:/app" javanile/fork.sh --hard
```


## Usage

### Forkfile magic variables

-  `Forkfile_name`  


## Contribute

### Development

```shell
git clone https://github.com/javanile/fork.sh.git
cd fork.sh
make init
make test
```


## Shorturl

```bash
curl -i "https://git.io" \
     -d "url=https://raw.githubusercontent.com/javanile/fork.sh/master/fork.sh" \
     -d "code=fork.sh"
```
