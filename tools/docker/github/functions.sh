#!/bin/sh

echo "------------------------------- Starting functions.sh -------------------------------"


get_port () {
  case $1 in
    lucee5)
      echo -n "60005"
      ;;
    lucee6)
      echo -n "60006"
      ;;
    lucee7)
      echo -n "60007"
      ;;
    adobe2016)
      echo -n "62016"
      ;;
    adobe2018)
      echo -n "62018"
      ;;
    adobe2021)
      echo -n "62021"
      ;;
    adobe2023)
      echo -n "62023"
      ;;
    adobe2025)
      echo -n "62025"
      ;;
    boxlang)
      echo -n "60001"
      ;;
    mysql56)
      echo -n "3306"
      ;;
    sqlserver)
      echo -n "1433"
      ;;
    postgres)
      echo -n "5432"
      ;;
    h2)
      echo -n "9092"
      ;;
    oracle)
      echo -n "1521"
      ;;
    *)
      echo -n "unknown"
      ;;
  esac
}

get_db () {
  case $1 in
    mysql56)
      echo -n "mysql"
      ;;
    *)
      echo -n "${1}"
      ;;
  esac
}

echo "------------------------------- Ending functions.sh -------------------------------"
