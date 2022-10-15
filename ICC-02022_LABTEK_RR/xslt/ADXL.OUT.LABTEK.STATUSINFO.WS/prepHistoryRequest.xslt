<!-- $Id: prepHistoryRequest.xslt 11018 2021-12-31 16:29:25Z jzajdel $  -->
<xsl:stylesheet version="2.0" exclude-result-prefixes="#all"
	xmlns:proc="http://processinghistory.gcmtools.scc.com"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Main match -->
	<xsl:template match="/">
		<proc:GetProcessingHistory>
			<proc:orderNumber>
				<xsl:value-of select="Message/Event/msg/attributes[name = 'ORDER']/value/text()"/>
			</proc:orderNumber>
			<proc:showHidden>Y</proc:showHidden>
			<proc:system>P</proc:system>
		</proc:GetProcessingHistory>
	</xsl:template>
</xsl:stylesheet>
