nagios-nconf-docker
===================
* Docker container for nagios+nconf
* will install from source - apache2,mysql,nagios,nconf,mysqlsetup for nconf.
* uses supervisord for process control.
* Generate Nagios config on nconf ui will executed deploy_local.sh internally
* All valid  generated confs pushed directly to inmobi-appops-nconf s3 and directly downloaded on container starts.
* To build container sudo docker build -t  tagname location of Dockerfile .eg sudo docker build -t  monsetup .
* To run docker container in background run
  sudo docker run  -d  -h desired docker hostname -e "stack=desired stack" -e "colo=required dc"  -p 80:80 -i -t   docker tag
* example : sudo docker run  -d  -h docker.geo.mon.hkg1.inmobi.com  -e "stack=geo" -e "colo=hkg1"  -p 80:80 -i -t      monsetup 
   
   
