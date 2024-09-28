#!/bin/bash
pls service ${service_name} stop
pls update-rc.d ${service_name} disable