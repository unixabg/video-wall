# video-wall
Simple web based 2D video wall NxN (rows x cols)

## Install
* clone the respository
* cd to the repository directory
* add a video.mp4 to the repository directory
* lanuch the server.py
```
 python3 server.py
```

## Utilizing from client browsers with example of 1 row and 2 cols
* On each client lannch browser with a url similar to http://serverIPAddress:8080/?hostname=rowPos-colPos-totalRows-totalCols
```
# wall position 0,0
http://serverIPAddress:8080/?hostname=0-0-1-2

# wall position 0,1
http://serverIPAddress:8080/?hostname=0-1-1-2

```
On either window now add the param &play=1 to the end of the url to trigger playing.

FIXME
