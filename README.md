# Downloader for Heise Magazines
This is a simple bash script to download magazines as PDF file from https://www.heise.de/select.

You will need an active subscription to download anything. This is just an alternative to clicking buttons in your browser.


## Usage
1) Download the script, mark as executable if needed
2) Edit script to include your email adress and password for heise.de (at the very beginning of the script)
2) Only for Windows Users: Install [Ubuntu for Windows](https://ubuntu.com/tutorials/ubuntu-on-windows#1-overview) 
3) Open the (Ubuntu) bash console terminal window.
4) Change to the directory you have downloaded the script to (e.g. `cd dl_for_heise`)
4) Run the script, e.g. to download all issues of the magazine c't from the year 2021:
`./download.sh ct 2021`
5) You will find all downloaded PDF files as well as .jpg cover thumbnails in newly created subfolders divided by magazine name and year.

## Further Options
- download all c't magazines between 2014 and 2022: `./download.sh ct 2014 2022`
- download other magazines: replace `ct` with whatever is in the URL of the [heise archive page](https://www.heise.de/select), e.g. for the archive of Make: `https://www.heise.de/select/make/archiv` the correct name is `make`, and for Retro Gamer `https://www.heise.de/select/retro-gamer/archiv`, the correct name is `retro-gamer`. Further options include: `ix`, `tr`, `mac-and-i`, `ct-foto`, `ct-wissen`, `ix-special`, ...
- display additional console output by adding -v at the beginning of the command: `./download.sh -v ct 2014 2022`

## Common Failures
- sometimes heise does not provide proper PDF files but internal server errors, the script will detect this and retry a few times (see  `max_tries_per_download` in the script)
- already downloaded files will not be downloaded again
- if you are not authorized to download a certain issue, the script will retry a few times and finally skip the file.
- make sure to replace your email and password in the script

## I only get "Server refused connection, you might not be allowed to download this issue" errors
There seem to be different heise+ subscription models and some users cannot download the whole issue, but only single articles.
If you see the error `erver refused connection, you might not be allowed to download this issue` you are certainly one of them and need to resort to the other download script that downloads and merges individually articles.

For that install GhostScript (under Linux) and mark the download script executable:
```
sudo apt-get install gs
chmod a+x download_articles.sh
```

Edit the script `download_articles.sh` and adapt email and password. The usage is exactly like `download.sh`.

## Example Output
```
Heise Magazine Downloader v1.0
Logging in...
[ct][2022/01][SKIP] Already downloaded.
[ct][2022/02] Downloading...
################################################################################################################# 100.0%
[ct][2022/02][SUCCESS] Downloaded ct/2022/ct.2022.02.pdf (size: 18488221)
[ct][2022/03][SKIP] Magazine issue does not exist on the server, skipping.
...
```

## Thank you to everyone who made this possible!
MyDealz usernames: *tehlers*, *joboza*, *dasd1*

Please submit pull requests and write issues in this project if you want to further improve this script.

## Disclaimer
This poject is a community based non-commercial project and not affiliated with Heise Medien GmbH & Co. KG. The script only acts as a client to download files otherwise available via your webbrowser. It does not circumvent any security measures made by the magazines publishers, without an active subscription to their services no downloads will be possible.
