#!/bin/bash

./stripe listen --forward-to localhost:3000/webhooks &

bin/rails s

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
