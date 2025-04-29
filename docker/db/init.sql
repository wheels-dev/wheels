-- MySQL initialization script for Wheels Docker setup
CREATE DATABASE IF NOT EXISTS wheels;
USE wheels;

-- Create a user for the application
CREATE USER IF NOT EXISTS 'wheels'@'%' IDENTIFIED BY 'wheels';
GRANT ALL PRIVILEGES ON wheels.* TO 'wheels'@'%';
FLUSH PRIVILEGES;

-- Add your schema initialization here or use migrations
