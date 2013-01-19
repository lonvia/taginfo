#!/bin/sh
#
#  Taginfo source: Wiki
#
#  update.sh DIR
#

set -e

DIR=$1

DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo "`$DATECMD` Start wiki..."

DATABASE=$DIR/taginfo-wiki.db
CACHEDB=$DIR/wikicache.db
LOGFILE_WIKI_DATA=$DIR/get_wiki_data.log
LOGFILE_IMAGE_INFO=$DIR/get_image_info.log

rm -f $DIR/allpages.list
rm -f $DIR/tagpages.list
rm -f $LOGFILE
rm -f $DATABASE

if [ ! -e $CACHEDB ]; then
    sqlite3 $CACHEDB <cache.sql
fi

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Getting page list..."
./get_page_list.rb $DIR

echo "`$DATECMD` Getting wiki data..."
./get_wiki_data.rb $DIR >$LOGFILE_WIKI_DATA

echo "`$DATECMD` Getting image info..."
./get_image_info.rb $DIR >$LOGFILE_IMAGE_INFO

echo "`$DATECMD` Extracting words..."
./extract_words.rb $DIR

echo "`$DATECMD` Running post.sql..."
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done wiki."

