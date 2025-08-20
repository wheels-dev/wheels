/**
 * Factory Service for generating test data
 * Provides a fluent API for creating test objects with sensible defaults
 */
component singleton {
	
	property name="factories" type="struct";
	property name="sequences" type="struct";
	
	/**
	 * Constructor
	 */
	function init() {
		variables.factories = {};
		variables.sequences = {};
		
		// Register default factories
		registerDefaultFactories();
		
		return this;
	}
	
	/**
	 * Register a factory definition
	 *
	 * @name The name of the factory
	 * @definition The factory definition (struct or closure)
	 */
	function define(required string name, required any definition) {
		variables.factories[arguments.name] = arguments.definition;
		return this;
	}
	
	/**
	 * Build an instance without saving
	 *
	 * @name The factory name
	 * @attributes Attribute overrides
	 */
	function build(required string name, struct attributes = {}) {
		if (!structKeyExists(variables.factories, arguments.name)) {
			throw(type="FactoryService.FactoryNotFound", message="Factory '#arguments.name#' not found");
		}
		
		var definition = variables.factories[arguments.name];
		var modelName = arguments.name;
		var attrs = {};
		
		// Handle closure definitions
		if (isCustomFunction(definition) || isClosure(definition)) {
			attrs = definition(this);
		} else if (isStruct(definition)) {
			// Handle struct definitions
			if (structKeyExists(definition, "model")) {
				modelName = definition.model;
			}
			
			// Build attributes from definition
			for (var key in definition) {
				if (key != "model") {
					if (isCustomFunction(definition[key]) || isClosure(definition[key])) {
						attrs[key] = definition[key](this);
					} else {
						attrs[key] = definition[key];
					}
				}
			}
		}
		
		// Apply overrides
		structAppend(attrs, arguments.attributes, true);
		
		// Create model instance
		try {
			var model = application.wo.model(modelName).new(attrs);
		} catch (any e) {
			// Fallback for older Wheels versions
			var model = createObject("component", "app.models.#modelName#").new(attrs);
		}
		
		return model;
	}
	
	/**
	 * Create an instance and save it
	 *
	 * @name The factory name
	 * @attributes Attribute overrides
	 */
	function create(required string name, struct attributes = {}) {
		var instance = build(argumentCollection=arguments);
		
		if (!instance.save()) {
			var errors = instance.allErrors();
			var errorMessage = "Failed to create #arguments.name#. Errors: #serializeJSON(errors)#";
			throw(type="FactoryService.CreateFailed", message=errorMessage);
		}
		
		return instance;
	}
	
	/**
	 * Create multiple instances
	 *
	 * @name The factory name
	 * @count Number to create
	 * @attributes Attributes (can be array of structs for individual overrides)
	 */
	function createList(required string name, required numeric count, any attributes = {}) {
		var list = [];
		
		for (var i = 1; i <= arguments.count; i++) {
			var attrs = {};
			
			if (isArray(arguments.attributes) && arrayLen(arguments.attributes) >= i) {
				attrs = arguments.attributes[i];
			} else if (isStruct(arguments.attributes)) {
				attrs = duplicate(arguments.attributes);
			}
			
			arrayAppend(list, create(arguments.name, attrs));
		}
		
		return list;
	}
	
	/**
	 * Generate a sequence number
	 *
	 * @name The sequence name
	 * @start Starting number (default: 1)
	 */
	function sequence(required string name, numeric start = 1) {
		if (!structKeyExists(variables.sequences, arguments.name)) {
			variables.sequences[arguments.name] = arguments.start;
		} else {
			variables.sequences[arguments.name]++;
		}
		
		return variables.sequences[arguments.name];
	}
	
	/**
	 * Generate fake data using various methods
	 */
	function fake() {
		return {
			// Names
			firstName: function() {
				var names = ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Edward", "Fiona", "George", "Helen"];
				return names[randRange(1, arrayLen(names))];
			},
			
			lastName: function() {
				var names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"];
				return names[randRange(1, arrayLen(names))];
			},
			
			fullName: function() {
				return fake().firstName() & " " & fake().lastName();
			},
			
			// Contact
			email: function(name = "") {
				if (!len(arguments.name)) {
					arguments.name = fake().firstName() & "." & fake().lastName();
				}
				return lCase(arguments.name) & sequence("email") & "@example.com";
			},
			
			phone: function() {
				return "+1-555-" & numberFormat(randRange(100, 999), "000") & "-" & numberFormat(randRange(1000, 9999), "0000");
			},
			
			// Address
			streetAddress: function() {
				var number = randRange(1, 9999);
				var streets = ["Main St", "Oak Ave", "Elm St", "Park Rd", "First Ave", "Second St", "Maple Dr", "Cedar Ln", "Pine St", "Washington Blvd"];
				return number & " " & streets[randRange(1, arrayLen(streets))];
			},
			
			city: function() {
				var cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose"];
				return cities[randRange(1, arrayLen(cities))];
			},
			
			state: function() {
				var states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA"];
				return states[randRange(1, arrayLen(states))];
			},
			
			zipCode: function() {
				return numberFormat(randRange(10000, 99999), "00000");
			},
			
			// Business
			companyName: function() {
				var prefixes = ["Acme", "Global", "United", "National", "International", "Premier", "First", "Advanced", "Digital", "Smart"];
				var suffixes = ["Corp", "Inc", "LLC", "Group", "Solutions", "Services", "Industries", "Enterprises", "Partners", "Holdings"];
				return prefixes[randRange(1, arrayLen(prefixes))] & " " & suffixes[randRange(1, arrayLen(suffixes))];
			},
			
			// Internet
			url: function() {
				return "https://www.example" & sequence("url") & ".com";
			},
			
			username: function() {
				return lCase(fake().firstName()) & sequence("username");
			},
			
			password: function() {
				return "Test123!@" & sequence("password");
			},
			
			// Numbers
			randomNumber: function(min = 1, max = 100) {
				return randRange(arguments.min, arguments.max);
			},
			
			price: function(min = 10, max = 1000) {
				return randRange(arguments.min * 100, arguments.max * 100) / 100;
			},
			
			// Dates
			pastDate: function(daysAgo = 30) {
				return dateAdd("d", -randRange(1, arguments.daysAgo), now());
			},
			
			futureDate: function(daysAhead = 30) {
				return dateAdd("d", randRange(1, arguments.daysAhead), now());
			},
			
			// Text
			sentence: function(wordCount = 10) {
				var words = ["the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog", "and", "runs", "fast", "very", "much", "so", "well", "good", "nice", "great", "best", "top"];
				var sentence = [];
				
				for (var i = 1; i <= arguments.wordCount; i++) {
					arrayAppend(sentence, words[randRange(1, arrayLen(words))]);
				}
				
				var result = arrayToList(sentence, " ");
				return uCase(left(result, 1)) & right(result, len(result) - 1) & ".";
			},
			
			paragraph: function(sentenceCount = 5) {
				var sentences = [];
				
				for (var i = 1; i <= arguments.sentenceCount; i++) {
					arrayAppend(sentences, fake().sentence());
				}
				
				return arrayToList(sentences, " ");
			}
		};
	}
	
	/**
	 * Register default factories
	 */
	private function registerDefaultFactories() {
		// User factory
		define("user", function(factory) {
			return {
				firstName: factory.fake().firstName(),
				lastName: factory.fake().lastName(),
				email: factory.fake().email(),
				password: factory.fake().password(),
				createdAt: now(),
				updatedAt: now()
			};
		});
		
		// Product factory
		define("product", function(factory) {
			return {
				name: "Product " & factory.sequence("product"),
				description: factory.fake().paragraph(),
				price: factory.fake().price(),
				sku: "SKU-" & factory.sequence("sku"),
				inStock: true,
				createdAt: now(),
				updatedAt: now()
			};
		});
		
		// Order factory
		define("order", function(factory) {
			return {
				orderNumber: "ORD-" & dateFormat(now(), "yyyymmdd") & "-" & factory.sequence("order"),
				status: "pending",
				total: factory.fake().price(50, 500),
				createdAt: now(),
				updatedAt: now()
			};
		});
		
		// Category factory
		define("category", function(factory) {
			return {
				name: "Category " & factory.sequence("category"),
				slug: "category-" & factory.sequence("category"),
				description: factory.fake().sentence(),
				createdAt: now(),
				updatedAt: now()
			};
		});
		
		// Comment factory
		define("comment", function(factory) {
			return {
				author: factory.fake().fullName(),
				email: factory.fake().email(),
				content: factory.fake().paragraph(),
				approved: true,
				createdAt: now(),
				updatedAt: now()
			};
		});
	}
}