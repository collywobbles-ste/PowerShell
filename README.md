# PHP install script for Server Core installations

This script can be used to install various versions of PHP from http://windows.php.net
Ideal for server core installations

The script accepts the parameter -version followed by the version number (e.g. -version 7.1).

The latest branch of the version will be searched for and installed. A search for 7.1 will (as of typing this) install 7.1.6.
If you want to specify an exact version, you can do (e.g. 5.6.30).

By default the x64 bit version will be installed (If available).

The script will register the version in the system path if it's newer than an already installed version.
Finally, it will be registered in IIS.
