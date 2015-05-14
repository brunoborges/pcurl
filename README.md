# pcurl
Fork from http://sourceforge.net/projects/pcurl/ (no changes)

# Usage on Dockerfiles
This script can help you to download files using cURL, with multiple connections. Here's an example:

        RUN curl -O -s https://raw.githubusercontent.com/brunoborges/pcurl/master/pcurl.sh
        RUN bash pcurl.sh http://somepage.com/somepackage.zip

This will download the file **somepackage.zip** using up to 10 multiple connections.
