# Model Methods Reference

## Description
Comprehensive reference for all CFWheels model methods including CRUD operations, associations, validations, and advanced features.

## Key Points
- All models extend `wheels.Model` for ORM functionality
- Methods are categorized by usage: class methods, instance methods, configuration methods
- Use consistent argument syntax (all named OR all positional)
- Associations return QUERY objects, not arrays

## Core Model Methods

### Class Methods (called on model class)
- **`findAll()`** - Find multiple records with conditions
- **`findByKey(key)`** - Find single record by primary key
- **`findOne()`** - Find single record with conditions
- **`create(properties)`** - Create and save new record
- **`new(properties)`** - Create new unsaved record
- **`updateAll()`** - Update multiple records
- **`deleteAll()`** - Delete multiple records
- **`count()`** - Count records matching conditions
- **`exists()`** - Check if records exist

### Instance Methods (called on model object)
- **`save()`** - Save changes to database
- **`update(properties)`** - Update and save record
- **`delete()`** - Delete record from database
- **`valid()`** - Check if record passes validation
- **`hasErrors()`** - Check if record has validation errors
- **`reload()`** - Reload record from database

### Configuration Methods (used in config())
- **`property()`** - Define custom properties and mappings
- **`table()`** - Specify database table name
- **`dataSource()`** - Specify custom data source for this model
- **`belongsTo(name="model name", foreignKey="")`** - Define parent relationship
- **`hasMany()`** - Define child collection relationship
- **`hasOne()`** - Define one-to-one relationship
- **`validate*()`** - Define validation rules
- **`validate(method="")`** - Define custom validation methods
- **`nestedProperties()`** - Enable saving of associated models in single operation
- **`timeStampOnCreateProperty`** - Enable automatic createdAt timestamp using `set` function
- **`timeStampOnUpdateProperty`** - Enable automatic updatedAt timestamp using `set` function
- **`protectedProperties()`** - Protect properties from mass assignment
- **`accessibleProperties()`** - Allow specific properties for mass assignment

### Query and Statistical Methods
- **`sum(property)`** - Calculate sum of property values
- **`average(property)`** - Calculate average of property values
- **`minimum(property)`** - Find minimum property value
- **`maximum(property)`** - Find maximum property value
- **`invokeWithTransaction()`** - Execute method within transaction

### Change Tracking Methods
- **`hasChanged(property="")`** - Check if object/property has changed
- **`changedFrom(property)`** - Get previous value of property
- **`changedProperties()`** - Get list of changed property names
- **`allChanges()`** - Get struct of all changes (names and values)
- **`isNew()`** - Check if object is new (not yet saved to database)

### Dynamic Finder Methods
- **`findOneBy[Property](value)`** - Dynamic finder for single property
- **`findAllBy[Property](value)`** - Dynamic finder for single property
- **`findOneBy[Property]And[Property](values)`** - Dynamic finder for multiple properties
- **`[property]HasChanged()`** - Dynamic change check for specific property
- **`[property]ChangedFrom()`** - Dynamic previous value check for specific property

## Important Notes
- CFWheels models do NOT have a `scope()` function (use custom finder methods)
- Associations return QUERY objects, use `.recordCount` not `ArrayLen()`
- Always use consistent argument syntax in method calls
- Model names are SINGULAR (User.cfc → users table)