# Yosp

## 1. 95th percentile bash script using bc.

```
[vagrant@yosp vagrant]$ ./percentile.sh

###########
## Parse log file for 95th percentile values
##
## Options:
## -h: find 95th percentile hourly
## -t: find 95th percentile per request-type
## -v: enable verbose results
##
## Usage: percentile.sh [-v]  [-h] [-t request_type ] logfile.log
###########

ERROR: Please provide a valid log file.
[vagrant@yosp vagrant]$
```

### Results

Part 1: 
```
[vagrant@yosp vagrant]$ ./percentile.sh example.log
1757
[vagrant@yosp vagrant]$
```
Part 2:
```
[vagrant@yosp vagrant]$ ./percentile.sh -h example.log
2023032200: 1757
2023032201: 3750
2023032202: 1553
[vagrant@yosp vagrant]$
```
Part 3: 
```
[vagrant@yosp vagrant]$ ./percentile.sh -t Entity4 example.log
5653
[vagrant@yosp vagrant]$
```
Part 4:
```
[vagrant@yosp vagrant]$ ./percentile.sh -h -t Entity4 example.log
2023032200: 5653
2023032201: 3750
2023032202: 1553
[vagrant@yosp vagrant]$
```


## 2. Apache install with mod_cache_disk module

```
[vagrant@yosp vagrant]$ cat apache/setup_apache.sh
#!/bin/bash
# setup apache, caching, and install bc for 95th percentile script
# Ian Haddock Aug 5 2021


# install apache, tools, and bc for the script
#sudo dnf update -y
sudo dnf install -y httpd httpd-tools bc

# add folders
if [ ! -d /var/www/cache ]; then
  sudo mkdir /var/www/cache
  sudo chown apache:apache /var/www/cache
fi

if [ ! -d /var/www/html/logs_output ]; then
  sudo mkdir /var/www/html/logs_output
fi

# add test content
sudo cp -v ./part3and4.txt /var/www/html/logs_output/
sudo cp -v ./part1and2.txt /var/www/html/logs_output/

# add apache configs
sudo cp -v ./99-mod_cache_disk.conf /etc/httpd/conf.modules.d/99-mod_cache_disk.conf
sudo cp -v ./output.conf /etc/httpd/conf.d/output.conf

# add 18080 to SELinux http port allow rules
sudo semanage port -a -t http_port_t -p tcp 18080

# startup apache
sudo systemctl enable httpd
sudo systemctl start httpd

# test
echo "### httpd -t output:"
sudo httpd -t


exit 0

[vagrant@yosp vagrant]$
```

### Results:

```
[vagrant@yosp vagrant]$ curl -v localhost:18080/part3and4.txt
*   Trying ::1:18080...
* Connected to localhost (::1) port 18080 (#0)
> GET /part3and4.txt HTTP/1.1
> Host: localhost:18080
> User-Agent: curl/7.76.1
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Tue, 06 Aug 2024 20:08:29 GMT
< Server: Apache/2.4.57 (CentOS Stream)
< Last-Modified: Tue, 06 Aug 2024 20:03:26 GMT
< ETag: "38-61f094962b5b8"
< Accept-Ranges: bytes
< Content-Length: 56
< Cache-Control: max-age=86400, public
< Age: 281
< Content-Type: text/plain; charset=UTF-8
<
5653
2023032200: 5653
2023032201: 3750
2023032202: 1553
* Connection #0 to host localhost left intact
[vagrant@yosp vagrant]$
```


