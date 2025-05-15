#!/bin/bash
if [ -f "start.sh" ]; then
  ./start.sh
else
  case $SERVICE in
  *)
    bundle exec puma -C config/puma.rb -e production
    ;;
  esac
fi

