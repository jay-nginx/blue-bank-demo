#!/usr/bin/env bash
#
# swagger2nginx.sh (c) NGINX, Inc. [v0.2 03-May-2018] Liam Crilly <liam.crilly@nginx.com>
#
# Requires shyaml for YAML processing: https://github.com/0k/shyaml

if [ $# -lt 1 ]; then
    echo "### USAGE: `basename $0` [options] swagger_file.yaml"
    echo "### Options:"
    echo "### -b | --basepath <basePath>       # Override Swagger basePath"
    echo "### -l | --location                  # Create policy location (requires -u)"
    echo "### -n | --api-name <API name>       # Override Swagger title"
    echo "### -p | --prefix <prefix path>      # Apply prefix to basePath"
    echo "### -u | --upstream <upstream name>  # Specify upstream group"
    exit 1
fi

which shyaml
if [ $? -ne 0 ]; then
    echo "### `basename $0` ERROR: shyaml not found, see https://github.com/0k/shyaml"
    exit 1
fi

API_NAME=""
DO_LOCATION=0
BASEPATH=""
PREFIX_PATH=""
UPSTREAM=""
while [ $# -gt 1 ]; do
    case "$1" in
        "-b" | "--basepath")
            BASEPATH=$2
            shift; shift
            ;;
        "-l" | "--location")
            DO_LOCATION=1
            shift
            ;;
        "-n" | "--api-name")
            API_NAME=$2
            shift; shift
            ;;
        "-p" | "--prefix")
            PREFIX_PATH=$2
            shift; shift
            ;;
        "-u" | "--upstream")
            UPSTREAM=$2
            shift; shift
            ;;
         *)
            echo "### `basename $0` ERROR: Invalid command line option ($1)"
            exit 1
            ;;
    esac
done

if [ $DO_LOCATION -eq 1 ] && [ "$UPSTREAM" == "" ]; then
    echo "### `basename $0` ERROR: Policy location requires upstream --upstream name"
    exit 1
fi

if [ ! -f $1 ]; then
    echo "### `basename $0` ERROR: Cannot open $1"
    exit 1
fi

if [ "$API_NAME" == "" ]; then
    # Convert title to NGINX-friendly API name
    API_NAME=`shyaml get-value info.title < $1 | tr '[:space:]' '_' | tr -cd '[:alnum:]_-' 2> /dev/null`
    if [ "$API_NAME" == "" ]; then
        echo "### `basename $0` ERROR: Swagger file has missing/invalid title for API name"
        exit 1
    fi
fi

if [ "$BASEPATH" == "" ]; then
    BASEPATH=`shyaml get-value basePath < $1 2> /dev/null`
    if [ "$BASEPATH" == "" ]; then
        echo "### `basename $0` ERROR: No basePath found in Swagger"
        exit 1
    fi
fi
BASEPATH=$PREFIX_PATH$BASEPATH

for SWAGGER_PATH in `shyaml keys paths < $1`; do
    # Convert path templates to regular expressions
    URI=`echo $SWAGGER_PATH | sed -e "s/\({.*}\)/\[\^\/\]\*/g"`

    if [ "$SWAGGER_PATH" == "$URI" ]; then
        echo "location = $BASEPATH$URI {"    # Exact match when no path templates
    else
        echo "location ~ ^$BASEPATH$URI\$ {" # Regex match
    fi

    METHODS=`shyaml keys paths.$SWAGGER_PATH < $1 | grep -v parameters | tr '\n' ' '`
    if [ "$METHODS" != "" ]; then
        echo "    limit_except $METHODS{}"
    fi

    if [ "$UPSTREAM" != "" ]; then
        echo "    set \$upstream $UPSTREAM;"
    fi

    echo "    rewrite ^ /_$API_NAME last;"
    echo "}"
done

if [ $DO_LOCATION -eq 1 ]; then
    echo ""
    echo "location = /_$API_NAME {"
    echo "    proxy_pass http://\$upstream\$request_uri;"
    echo "}"
fi
