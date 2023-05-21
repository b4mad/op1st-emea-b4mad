#!/bin/env bash

indent_arrow() { sed 's/^/  -> /'; }
indent() { sed 's/^/     /'; }

oc get apirequestcounts -o jsonpath='{range .items[?(@.status.removedInRelease!="")]}{.status.removedInRelease}{"\t"}{.metadata.name}{"\t"}{.status.currentHour.requestCount}{"\t"}{.status.requestCount}{"\n"}{end}' | sort |
    while read version endpoint count1h count24h; do
        echo "endpoint '$endpoint' is deprecated in version '$version'" | indent_arrow
        if [ $count24h -ne 0 ]; then
            echo "# of calls: $count1h (last 1h), $count24h (last 24h)" | indent_arrow | indent
            echo "it was called by the following callers in last 24h:" | indent_arrow | indent
            oc get apirequestcounts $endpoint -o jsonpath='{range ..username}{$}{"\n"}{end}' | sort -u | indent_arrow | indent | indent
        else
            echo "it was not called in last 24h" | indent_arrow | indent
        fi
    done
