# Parameters

Many commands accept parameters to control how they function. Parameters are entered on the same line as the command and separated by a space and can be provided as named OR positional, similar to how CFML functions can be called. You cannot mix named and positional parameters in the same command though or an error will be thrown. There is also a concept of "flag" for boolean parameters that can be combined with named or positional parameters for brevity and readability.

## Named Parameters

Named parameters can be specified in any order and follow the format `name=value`. Multiple named parameters are separated by a space.

```bash
coldbox create app name=myApp skeleton=AdvancedScript directory=myDir init=true
```

## Positional Parameters

Positional parameters omit the `name=` part and only use the value. They must be supplied in the order shown in the [Command API docs](http://apidocs.ortussolutions.com/commandbox/current) or help command. We try to place the most common parameters at the beginning so you can use named parameters easily. Here is the equivalent of the named command above:

```bash
coldbox create app myApp AdvancedScript myDir true
```

Of course, only the required parameters must be specified. I'm only including all of them here for the completeness of the example.

## Required Parameters

If you do not provide a parameter that is required for the command execution, the shell will stop and ask you for each of the missing parameters before the command will execute.

```bash
CommandBox> mkdir
Enter directory (The directory to create) : myDir
Created C:\myDir
CommandBox>
```

> **Info** It is not necessary to escape special characters in parameter values that are collected in this manner since the shell doesn't need to parse them. The exact value you enter is used.

## Funky Parameters

In addition to quoting parameter values, parameter names can also be quoted.  This is useful when setting keys into settings or JSON files that have spaces, hyphens or special characters.  Each of these examples are supported:

```bash
# quoted string
package set foo."bar.baz"=bum

# bracketed string
package set foo[bar.baz]=bum

# quoted, bracketed string
package set foo["bar.baz"]=bum
```

Each of those examples will create this in your `box.json`

```javascript
{
  "foo":{
        "bar.baz":"bum"
  }
}
```

## Flags

Any parameter that is a boolean type can be specified as a flag in the format `--name`. Flags can be mixed with named or positional parameters and can appear anywhere in the list. Putting the flag in the parameter list sets that parameter to true. This can be very handy if you want to use positional parameters on a command with a large amount of optional parameters, but you don't want to specify all the in-between ones.

```bash
coldbox create app myApp --init --installColdBox
```

You can also negate a flag by putting an exclamation point or the word "no" before the name in the format `--no{paramName}`. This sets the parameter to false which can be handy to turn off features that default to true.

```bash
coldbox create app myApp --noInit
```
