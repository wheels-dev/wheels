<cfscript>
		// Possible formats for provides functionality.
		application.$wheels.formats = {};
		application.$wheels.formats.html = "text/html";
		application.$wheels.formats.xml = "text/xml";
		application.$wheels.formats.json = "application/json";
		application.$wheels.formats.csv = "text/csv";
		application.$wheels.formats.pdf = "application/pdf";
		application.$wheels.formats.xls = "application/vnd.ms-excel";

		// Mime types.
		application.$wheels.mimetypes = {
			txt = "text/plain",
			gif = "image/gif",
			jpg = "image/jpg",
			jpeg = "image/jpg",
			pjpeg = "image/jpg",
			png = "image/png",
			wav = "audio/wav",
			mp3 = "audio/mpeg3",
			pdf = "application/pdf",
			zip = "application/zip",
			ppt = "application/powerpoint",
			pptx = "application/powerpoint",
			doc = "application/word",
			docx = "application/word",
			xls = "application/excel",
			xlsx = "application/excel"
		};
</cfscript>
