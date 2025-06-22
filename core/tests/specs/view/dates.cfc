component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that distanceOfTimeInWords", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				f = "distanceOfTimeInWords"
				args = {}
				args.fromTime = Now()
				args.includeSeconds = true
			})

			it("works with seconds below 5 seconds", () => {
				c = 5 - 1
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("less than 5 seconds")
			})

			it("works with seconds below 10 seconds", () => {
				c = 10 - 1
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("less than 10 seconds")
			})

			it("works with seconds below 20 seconds", () => {
				c = 20 - 1
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("less than 20 seconds")
			})

			it("works with seconds below 40 seconds", () => {
				c = 40 - 1
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("half a minute")
			})

			it("works with seconds below 60 seconds", () => {
				c = 60 - 1
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("less than a minute")
			})

			it("works with seconds above 60 seconds", () => {
				c = 60 + 50
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("1 minute")
			})

			it("works without seconds below 60 seconds", () => {
				args.includeSeconds = false
				c = 60 - 1
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("less than a minute")
			})

			it("works without seconds above 60 seconds", () => {
				args.includeSeconds = false
				c = 60 + 50
				args.toTime = DateAdd('s', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("1 minute")
			})

			it("works without seconds below 45 minutes", () => {
				args.includeSeconds = false
				c = 45 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("44 minutes")
			})

			it("works without seconds below 90 minutes", () => {
				args.includeSeconds = false
				c = 90 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("about 1 hour")
			})

			it("works without seconds below 1440 minutes", () => {
				args.includeSeconds = false
				c = 1440 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				c = Ceiling(c / 60)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("about 24 hours")
			})

			it("works without seconds below 2880 minutes", () => {
				args.includeSeconds = false
				c = 2880 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("1 day")
			})

			it("works without seconds below 43200 minutes", () => {
				args.includeSeconds = false
				c = 43200 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				c = Int(c / 1440)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("29 days")
			})

			it("works without seconds below 86400 minutes", () => {
				args.includeSeconds = false
				c = 86400 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("about 1 month")
			})

			it("works without seconds below 525600 minutes", () => {
				args.includeSeconds = false
				c = 525600 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				c = Int(c / 43200)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("12 months")
			})

			it("works without seconds below 657000 minutes", () => {
				args.includeSeconds = false
				c = 657000 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("about 1 year")
			})

			it("works without seconds below 919800 minutes", () => {
				args.includeSeconds = false
				c = 919800 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("over 1 year")
			})

			it("works without seconds below 1051200 minutes", () => {
				args.includeSeconds = false
				c = 1051200 - 1
				args.toTime = DateAdd('n', c, args.fromTime)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("almost 2 years")
			})

			it("works without seconds above 1051200 minutes", () => {
				args.includeSeconds = false
				c = 1051200
				c = (c * 3) + 786
				args.toTime = DateAdd('n', c, args.fromTime)
				c = Int(c / 525600)
				actual = _controller.distanceOfTimeInWords(argumentCollection = args)

				expect(actual).toBe("over 6 years")
			})
		})

		describe("Tests that timeAgoInWords", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				now = Now()
				args = {}
				args.includeSeconds = true
				args.toTime = now
			})

			it("works with seconds below 5 secondss", () => {
				c = 5 - 1
				args.fromTime = DateAdd('s', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("less than 5 seconds")
			})

			it("works with seconds below 10 secondss", () => {
				c = 10 - 1
				args.fromTime = DateAdd('s', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("less than 10 seconds")
			})

			it("works with seconds below 20 secondss", () => {
				c = 20 - 1
				args.fromTime = DateAdd('s', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("less than 20 seconds")
			})

			it("works with seconds below 40 secondss", () => {
				c = 40 - 1
				args.fromTime = DateAdd('s', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("half a minute")
			})

			it("works with seconds below 60 secondss", () => {
				c = 60 - 1
				args.fromTime = DateAdd('s', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("less than a minute")
			})

			it("works with seconds above 60 secondss", () => {
				c = 60 + 50
				args.fromTime = DateAdd('s', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("1 minute")
			})

			it("works without seconds above 60 seconds", () => {
				args.includeSeconds = false;
				c = 60 + 50
				args.fromTime = DateAdd('s', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("1 minute")
			})

			it("works without seconds below 45 minutes", () => {
				args.includeSeconds = false;
				c = 45 - 1
				args.fromTime = DateAdd('n', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("44 minutes")
			})

			it("works without seconds below 90 minutes", () => {
				args.includeSeconds = false;
				c = 90 - 1
				args.fromTime = DateAdd('n', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("about 1 hour")
			})

			it("works without seconds below 1440 minutes", () => {
				args.includeSeconds = false;
				c = 1440 - 1
				args.fromTime = DateAdd('n', -c, now)
				c = Ceiling(c / 60)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("about 24 hours")
			})

			it("works without seconds below 2880 minutes", () => {
				args.includeSeconds = false;
				c = 2880 - 1
				args.fromTime = DateAdd('n', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("1 day")
			})

			it("works without seconds below 43200 minutes", () => {
				args.includeSeconds = false;
				c = 43200 - 1
				args.fromTime = DateAdd('n', -c, now)
				c = Int(c / 1440)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("29 days")
			})

			it("works without seconds below 86400 minutes", () => {
				args.includeSeconds = false;
				c = 86400 - 1
				args.fromTime = DateAdd('n', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("about 1 month")
			})

			it("works without seconds below 525600 minutes", () => {
				args.includeSeconds = false;
				c = 525600 - 1
				args.fromTime = DateAdd('n', -c, now)
				c = Int(c / 43200)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("12 months")
			})

			it("works without seconds below 1051200 minutes", () => {
				args.includeSeconds = false;
				c = 1051200 - 1
				args.fromTime = DateAdd('n', -c, now)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("almost 2 years")
			})

			it("works without seconds above 1051200 minutes", () => {
				args.includeSeconds = false;
				c = 1051200
				c = (c * 3) + 786
				args.fromTime = DateAdd('n', -c, now)
				c = Int(c / 525600)
				e = _controller.timeAgoInWords(argumentCollection = args)

				expect(e).toBe("over 6 years")
			})
		})

		describe("Tests that timeUntilInWords", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				now = Now()
				args = {}
				args.includeSeconds = true
				args.fromTime = now
			})

			it("works with seconds below 5 secondss", () => {
				c = 5 - 1
				args.toTime = DateAdd('s', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("less than 5 seconds")
			})

			it("works with seconds below 10 secondss", () => {
				c = 10 - 1
				args.toTime = DateAdd('s', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("less than 10 seconds")
			})

			it("works with seconds below 20 secondss", () => {
				c = 20 - 1
				args.toTime = DateAdd('s', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("less than 20 seconds")
			})

			it("works with seconds below 40 secondss", () => {
				c = 40 - 1
				args.toTime = DateAdd('s', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("half a minute")
			})

			it("works with seconds below 60 secondss", () => {
				c = 60 - 1
				args.toTime = DateAdd('s', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("less than a minute")
			})

			it("works with seconds above 60 secondss", () => {
				c = 60 + 50
				args.toTime = DateAdd('s', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("1 minute")
			})

			it("works without seconds above 60 seconds", () => {
				args.includeSeconds = false;
				c = 60 + 50
				args.toTime = DateAdd('s', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("1 minute")
			})

			it("works without seconds below 45 minutes", () => {
				args.includeSeconds = false;
				c = 45 - 1
				args.toTime = DateAdd('n', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("44 minutes")
			})

			it("works without seconds below 90 minutes", () => {
				args.includeSeconds = false;
				c = 90 - 1
				args.toTime = DateAdd('n', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("about 1 hour")
			})

			it("works without seconds below 1440 minutes", () => {
				args.includeSeconds = false;
				c = 1440 - 1
				args.toTime = DateAdd('n', c, now)
				c = Ceiling(c / 60)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("about 24 hours")
			})

			it("works without seconds below 2880 minutes", () => {
				args.includeSeconds = false;
				c = 2880 - 1
				args.toTime = DateAdd('n', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("1 day")
			})

			it("works without seconds below 43200 minutes", () => {
				args.includeSeconds = false;
				c = 43200 - 1
				args.toTime = DateAdd('n', c, now)
				c = Int(c / 1440)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("29 days")
			})

			it("works without seconds below 86400 minutes", () => {
				args.includeSeconds = false;
				c = 86400 - 1
				args.toTime = DateAdd('n', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("about 1 month")
			})

			it("works without seconds below 525600 minutes", () => {
				args.includeSeconds = false;
				c = 525600 - 1
				args.toTime = DateAdd('n', c, now)
				c = Int(c / 43200)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("12 months")
			})

			it("works without seconds below 1051200 minutes", () => {
				args.includeSeconds = false;
				c = 1051200 - 1
				args.toTime = DateAdd('n', c, now)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("almost 2 years")
			})

			it("works without seconds above 1051200 minutes", () => {
				args.includeSeconds = false;
				c = 1051200
				c = (c * 3) + 786
				args.toTime = DateAdd('n', c, now)
				c = Int(c / 525600)
				e = _controller.timeUntilInWords(argumentCollection = args)

				expect(e).toBe("over 6 years")
			})
		})
	}
}