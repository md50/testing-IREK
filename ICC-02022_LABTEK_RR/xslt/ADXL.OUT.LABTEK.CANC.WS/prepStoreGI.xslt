<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: prepStoreGI.xslt 10877 2021-11-30 07:45:51Z rafalpa $  -->
<!--ADXL.OUT.LABTEK.NEWTEST.WS-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mom="http://mom.scc.com/" xmlns:rec="http://mom.scc.com/">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Template used to strip root 'join' element -->
	<xsl:template match="/">
		<xsl:apply-templates select="join/*"/>
	</xsl:template>
	<xsl:template match="Message/Header">
		<xsl:element name="Header">
			<xsl:copy-of select="*"/>
			<xsl:element name="Resource"><xsl:value-of select="'cancelTest'"/></xsl:element>
		</xsl:element>
	</xsl:template>
	<!-- copy copy -->
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
