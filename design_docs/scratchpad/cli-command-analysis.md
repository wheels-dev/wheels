# Wheels CLI Command Analysis

## Summary

### Total Counts:
- **Unique Base Commands**: 170
- **Total Command Permutations**: 542

## Detailed Analysis by Section

### CommandBox Basics (7 permutations)
- `box install` - 1
- `box` - 1  
- `box version` - 1
- `exit` - 1
- `curl` commands for installation - 3

### Server Management (18 permutations)
- `server start` - 6 variations
- `server status` - 1
- `server stop` - 1
- `server start name=myapp` - 1
- `server start port=8080` - 1
- `server start openBrowser=false` - 1
- Plus 6 more specific variations

### Wheels CLI Installation (5 permutations)
- `box wheels version` - 1
- `box install wheels-cli` - 1 
- `wheels version` - 1
- `wheels help` - 1
- `wheels help [command]` - 1

### Generator Commands (80 permutations)

#### Generate Application (11 permutations)
- `wheels g app` - 6 variations
- `wheels new` - 2 variations
- `wheels g app-wizard` - 2 variations 
- `wheels generate app-wizard` - 1

#### Generate Controller (6 permutations)
- `wheels g controller` - 6 variations including REST and API

#### Generate Model (8 permutations)  
- `wheels g model` - 8 variations with properties, associations, etc.

#### Generate Scaffold (6 permutations)
- `wheels g scaffold` - 6 variations including API and relationships

#### Generate View (4 permutations)
- `wheels g view` - 4 variations

#### Generate Migration (11 permutations)
- `wheels dbmigrate create` - 4 variations
- `wheels g migration` - 7 enhanced variations

#### Generate Test (4 permutations)
- `wheels g test` - 4 variations (model, controller, integration, helper)

#### Generate Snippets (2 permutations)
- `wheels g snippets` - 1
- `wheels generate snippets` - 1

#### Generate Mailer (5 permutations)
- `wheels g mailer` - 5 variations

#### Generate Service (6 permutations)
- `wheels g service` - 6 variations

#### Generate Helper (5 permutations)
- `wheels g helper` - 5 variations

#### Generate Job (5 permutations)
- `wheels g job` - 5 variations

#### Generate Plugin (5 permutations)
- `wheels g plugin` - 5 variations

### Database Commands (48 permutations)

#### Database Management (36 permutations)
- `wheels db create` - 3 variations
- `wheels db drop` - 3 variations
- `wheels db setup` - 3 variations
- `wheels db reset` - 4 variations
- `wheels db seed` - 4 variations
- `wheels db status` - 3 variations
- `wheels db version` - 2 variations
- `wheels db rollback` - 3 variations
- `wheels db dump` - 5 variations
- `wheels db restore` - 4 variations
- `wheels db shell` - 4 variations

#### Migration Management (8 permutations)
- `wheels dbmigrate latest` - 1
- `wheels dbmigrate up` - 1
- `wheels dbmigrate exec` - 1
- `wheels dbmigrate info` - 1
- `wheels dbmigrate down` - 1
- `wheels dbmigrate reset` - 1
- `wheels db schema` - 1
- Plus database shell examples - 1

### Testing Commands (40 permutations)

#### Basic Testing (11 permutations)
- `wheels test run` - 8 variations
- `wheels test app` - 1 (deprecated)
- `wheels test:match` - 2 variations

#### Advanced Testing (19 permutations)
- `wheels test:all` - 4 variations
- `wheels test:unit` - 3 variations
- `wheels test:integration` - 3 variations
- `wheels test:watch` - 4 variations
- `wheels test:coverage` - 5 variations

#### TestBox Integration (10 permutations)
- `box testbox run` - 7 variations
- `box testbox watch` - 1
- Plus 2 more variations

### Environment Commands (20 permutations)

#### Legacy Environment (3 permutations)
- `wheels get environment` - 1
- `wheels set environment` - 2 variations

#### New Environment Command (8 permutations)
- `wheels environment` - 8 variations including set, list, shortcuts

#### Console and Runner (9 permutations)
- `wheels console` - 4 variations
- `wheels runner` - 4 variations
- `wheels reload` - 1 variation

### Configuration Commands (45 permutations)

#### Config Commands (13 permutations)
- `wheels config dump` - 7 variations
- `wheels config check` - 4 variations
- `wheels config diff` - 3 variations

#### Secret Generation (5 permutations)
- `wheels secret` - 5 variations

#### Environment Variable Commands (15 permutations)
- `wheels env show` - 4 variations
- `wheels env set` - 3 variations
- `wheels env validate` - 4 variations
- `wheels env merge` - 3 variations

#### Legacy Config (8 permutations)
- `wheels get settings` - 2 variations
- `wheels set settings` - 1
- `wheels routes` - 2 variations
- Plus route matching - 3 variations

### Development Commands (60 permutations)

#### CommandBox Server (11 permutations)
- Various `server` commands

#### Wheels Server Commands (20 permutations)
- `wheels server start` - 7 variations
- `wheels server stop` - 3 variations
- `wheels server restart` - 2 variations
- `wheels server status` - 3 variations
- `wheels server log` - 4 variations
- `wheels server open` - 3 variations
- `wheels server` - 1

#### Code Formatting (5 permutations)
- `box run-script format` - 3 variations
- `box cfformat` - 2 variations

#### Development Workflow (24 permutations)
- `wheels init` - 4 variations
- `wheels upgrade` - 5 variations
- `wheels benchmark` - 7 variations
- `wheels profile` - 5 variations
- `wheels docs` - 3 variations

### Asset and Cache Management (26 permutations)

#### Asset Management (9 permutations)
- `wheels assets:precompile` - 3 variations
- `wheels assets:clean` - 3 variations
- `wheels assets:clobber` - 2 variations

#### Cache Management (5 permutations)
- `wheels cache:clear` - 5 variations

#### Log Management (6 permutations)
- `wheels log:clear` - 3 variations
- `wheels log:tail` - 3 variations

#### Temporary Files (6 permutations)
- `wheels tmp:clear` - 6 variations

### Package Management (8 permutations)
- Various `box install` and package commands

### Plugin Management (25 permutations)
- `wheels plugin search` - 4 variations
- `wheels plugin info` - 1
- `wheels plugin list` - 4 variations
- `wheels plugin install` - 5 variations
- `wheels plugin update` - 5 variations
- `wheels plugin outdated` - 2 variations
- `wheels plugin remove` - 2 variations
- `wheels plugin init` - 2 variations

### Maintenance Commands (24 permutations)

#### Maintenance Mode (8 permutations)
- `wheels maintenance:on` - 6 variations
- `wheels maintenance:off` - 3 variations

#### Cleanup Commands (16 permutations)
- `wheels cleanup:logs` - 6 variations
- `wheels cleanup:tmp` - 6 variations
- `wheels cleanup:sessions` - 6 variations

### Analysis and Optimization (18 permutations)
- `wheels analyze` - 6 variations
- `wheels optimize` - 3 variations
- `wheels security` - 3 variations
- `wheels watch` - 6 variations

### Application Utilities (23 permutations)

#### Route Management (7 permutations)
- `wheels routes` - 4 variations
- `wheels routes:match` - 3 variations

#### Application Info (2 permutations)
- `wheels about` - 1
- `wheels version` - 1

#### Code Analysis (4 permutations)
- `wheels stats` - 2 variations
- `wheels notes` - 4 variations

#### Health Checks (2 permutations)
- `wheels doctor` - 2 variations

#### Dependency Management (8 permutations)
- `wheels deptree` - 4 variations
- `wheels deps` - 5 variations

### Docker Commands (6 permutations)
- `wheels docker:init` - 4 variations
- `wheels docker:deploy` - 5 variations

### Deployment Commands (50 permutations)
- `wheels deploy` - 5 variations
- `wheels deploy:init` - 3 variations
- `wheels deploy:setup` - 3 variations
- `wheels deploy:push` - 4 variations
- `wheels deploy:rollback` - 4 variations
- `wheels deploy:status` - 4 variations
- `wheels deploy:logs` - 4 variations
- `wheels deploy:audit` - 4 variations
- `wheels deploy:exec` - 3 variations
- `wheels deploy:hooks` - 4 variations
- `wheels deploy:lock` - 4 variations
- `wheels deploy:proxy` - 4 variations
- `wheels deploy:secrets` - 5 variations
- `wheels deploy:stop` - 3 variations

### Security Commands (8 permutations)
- `wheels security` - 2 variations
- `wheels security:scan` - 7 variations

### Documentation Commands (8 permutations)
- `wheels docs` - 1
- `wheels docs:generate` - 5 variations
- `wheels docs:serve` - 4 variations

### CI/CD Commands (6 permutations)
- `wheels ci:init` - 6 variations

### Destroy Commands (22 permutations)
- `wheels destroy model` - 3 variations
- `wheels destroy controller` - 3 variations
- `wheels destroy scaffold` - 2 variations
- `wheels destroy view` - 3 variations
- `wheels destroy migration` - 2 variations
- `wheels destroy test` - 3 variations
- `wheels destroy mailer` - 2 variations
- `wheels destroy service` - 2 variations
- `wheels destroy helper` - 2 variations
- `wheels destroy job` - 2 variations
- `wheels destroy plugin` - 3 variations

### Additional Generators (9 permutations)
- `wheels g frontend` - 6 variations
- `wheels g property` - 4 variations
- `wheels g route` - 4 variations

### Miscellaneous (4 permutations)
- `wheels reload` - 4 variations

## Base Commands List (170 unique commands)

1. `box`
2. `box cfformat`
3. `box install`
4. `box list`
5. `box login`
6. `box package publish`
7. `box reload`
8. `box restart`
9. `box run-script`
10. `box testbox run`
11. `box testbox watch`
12. `box update`
13. `box version`
14. `box wheels version`
15. `exit`
16. `server open`
17. `server restart`
18. `server start`
19. `server status`
20. `server stop`
21. `wheels about`
22. `wheels analyze`
23. `wheels assets:clean`
24. `wheels assets:clobber`
25. `wheels assets:precompile`
26. `wheels benchmark`
27. `wheels cache:clear`
28. `wheels ci:init`
29. `wheels cleanup:logs`
30. `wheels cleanup:sessions`
31. `wheels cleanup:tmp`
32. `wheels config check`
33. `wheels config diff`
34. `wheels config dump`
35. `wheels console`
36. `wheels db create`
37. `wheels db drop`
38. `wheels db dump`
39. `wheels db reset`
40. `wheels db restore`
41. `wheels db rollback`
42. `wheels db schema`
43. `wheels db seed`
44. `wheels db setup`
45. `wheels db shell`
46. `wheels db status`
47. `wheels db version`
48. `wheels dbmigrate create`
49. `wheels dbmigrate down`
50. `wheels dbmigrate exec`
51. `wheels dbmigrate info`
52. `wheels dbmigrate latest`
53. `wheels dbmigrate reset`
54. `wheels dbmigrate up`
55. `wheels deploy`
56. `wheels deploy:audit`
57. `wheels deploy:exec`
58. `wheels deploy:hooks`
59. `wheels deploy:init`
60. `wheels deploy:lock`
61. `wheels deploy:logs`
62. `wheels deploy:proxy`
63. `wheels deploy:push`
64. `wheels deploy:rollback`
65. `wheels deploy:secrets`
66. `wheels deploy:setup`
67. `wheels deploy:status`
68. `wheels deploy:stop`
69. `wheels deps`
70. `wheels deptree`
71. `wheels destroy controller`
72. `wheels destroy helper`
73. `wheels destroy job`
74. `wheels destroy mailer`
75. `wheels destroy migration`
76. `wheels destroy model`
77. `wheels destroy plugin`
78. `wheels destroy scaffold`
79. `wheels destroy service`
80. `wheels destroy test`
81. `wheels destroy view`
82. `wheels docker:deploy`
83. `wheels docker:init`
84. `wheels docs`
85. `wheels docs:generate`
86. `wheels docs:serve`
87. `wheels doctor`
88. `wheels env merge`
89. `wheels env set`
90. `wheels env show`
91. `wheels env validate`
92. `wheels environment`
93. `wheels g app`
94. `wheels g app-wizard`
95. `wheels g controller`
96. `wheels g frontend`
97. `wheels g helper`
98. `wheels g job`
99. `wheels g mailer`
100. `wheels g migration`
101. `wheels g model`
102. `wheels g plugin`
103. `wheels g property`
104. `wheels g route`
105. `wheels g scaffold`
106. `wheels g service`
107. `wheels g snippets`
108. `wheels g test`
109. `wheels g view`
110. `wheels generate app-wizard`
111. `wheels generate snippets`
112. `wheels get environment`
113. `wheels get settings`
114. `wheels help`
115. `wheels init`
116. `wheels log:clear`
117. `wheels log:tail`
118. `wheels maintenance:off`
119. `wheels maintenance:on`
120. `wheels new`
121. `wheels notes`
122. `wheels optimize`
123. `wheels plugin info`
124. `wheels plugin init`
125. `wheels plugin install`
126. `wheels plugin list`
127. `wheels plugin outdated`
128. `wheels plugin remove`
129. `wheels plugin search`
130. `wheels plugin update`
131. `wheels plugin update:all`
132. `wheels profile`
133. `wheels reload`
134. `wheels routes`
135. `wheels routes:match`
136. `wheels runner`
137. `wheels secret`
138. `wheels security`
139. `wheels security:scan`
140. `wheels server`
141. `wheels server log`
142. `wheels server open`
143. `wheels server restart`
144. `wheels server start`
145. `wheels server status`
146. `wheels server stop`
147. `wheels set environment`
148. `wheels set settings`
149. `wheels stats`
150. `wheels test app`
151. `wheels test run`
152. `wheels test:all`
153. `wheels test:coverage`
154. `wheels test:integration`
155. `wheels test:unit`
156. `wheels test:watch`
157. `wheels tmp:clear`
158. `wheels upgrade`
159. `wheels version`
160. `wheels watch`
161. `box bump`
162. `box uninstall`
163. `cfpm install`
164. `curl`
165. `df`
166. `docker compose`
167. `git`
168. `mkdir`
169. `open`
170. `which`