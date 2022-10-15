<!-- $Id: filterHistory.xslt 11018 2021-12-31 16:29:25Z jzajdel $  -->
<xsl:stylesheet version="2.0" exclude-result-prefixes="#all"
	xmlns:proc="http://processinghistory.gcmtools.scc.com"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Main match -->
	<xsl:template match="*|/" mode="#all"><xsl:copy><xsl:apply-templates mode="#current"/></xsl:copy></xsl:template>
	<xsl:template match="text()|@*" mode="#all"><xsl:value-of select="string(.)"/></xsl:template>
	<xsl:template match="processing-instruction()|comment()" mode="#all"/>
	<xsl:template match="*:historyItems[not(*:ownerType = ('T','F')) or *:actionCompNotifFlag = 'false']"/>
</xsl:stylesheet>
