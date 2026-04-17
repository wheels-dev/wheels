---
title: ColdFusion on Wheels 1.1.6 Released
slug: 1-1-6-released
publishedAt: '2011-10-20T21:57:22.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Chris Peters
tags:
  - 1-1
categories:
  - Releases
excerpt: >-
  Another round of enhancements and bug fixes has been fixed and incorporated
  into version 1.1.6 of ColdFusion on Wheels. Download it
  today(https://cfwheels.org/download) to increase the stability of...
coverImage: null
legacyId: '72'
---

Another round of enhancements and bug fixes has been fixed and incorporated into version 1.1.6 of ColdFusion on Wheels. [Download it today](https://cfwheels.org/download) to increase the stability of your Wheels applications. **Upgrading from 1.1.x is easy.** Download the zip file, extract it, and replace your application's wheels folder with the new wheels folder from the zip file. Read on for details from the CHANGELOG.From the [CHANGELOG](https://github.com/cfwheels/cfwheels/blob/v1.1.6/wheels/CHANGELOG) for version 1.1.6...

### Model Enhancements

- validatesUniquenessOf only selects primary keys - \[Jordan Clark, Don Humphreys\]

### View Enhancements

- Allow removal height and/or width attributes from imageTag when set to false - \[downtroden, Tony Petruzzi\]
- Allow delimiter to be specified for stylesheets and javascripts - \[Derek, Tony Petruzzi\]

### Bug Fixes

- hasChanged was incorrectly evaluating boolean values - \[Jordan Clark, Don Humphreys\]
- Do not perform update when no changes have been made to the properties of a model - #786 \[Mohamad El-Husseini, Tony Petruzzi\]
- OnlyPath argument of urlFor does not correctly recognise HTTPS urls - \[Andy Bellenie, Tony Petruzzi\]
- Pagination clause wasn't enclosed - \[Karl Deterville, Tony Petruzzi\]
- Pagination endrow was incorrectly calculated - \[Karl Deterville, Tony Petruzzi\]
