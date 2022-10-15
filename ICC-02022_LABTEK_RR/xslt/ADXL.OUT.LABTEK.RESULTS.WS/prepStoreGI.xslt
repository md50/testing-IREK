<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: prepStoreGI.xslt 12142 2022-07-14 16:57:16Z rafalpa $  -->
<!-- ADXL.OUT.LABTEK.RESULTS.WS -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mom="http://mom.scc.com/" xmlns:rec="http://mom.scc.com/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Variables -->
	<xsl:variable name="billing" select="if (/join/Message//msg1//pv1/preadmitNumber/text()) then /join/Message//msg1//pv1/preadmitNumber else /join//Event/msg/attributes[name='BILLING']/value"/>
	<xsl:variable name="testId" select="/join//Event/msg/attributes[name='TEST']/value"/>
	<xsl:variable name="corrid" select="/join//Event/msg/attributes[name='CORRID']/value"/>
	<xsl:variable name="event" select="/join//Event/msg/attributes[name='EVENT']/value"/>
	<xsl:variable name="aux" select="/join/Message//msg1//orc/auxiliaryOrderNumber"/>
	<xsl:variable name="status" select="substring(/join/Message//msg1//obr/status,1,1)"/>
	<xsl:variable name="httpRespondCode" select="if (string(/join/Message[Data/HttpHeaders]/Data/Parameters/@httpRespondCode)) then /join/Message[Data/HttpHeaders]/Data/Parameters/@httpRespondCode else //SOAP-ENV:Fault/detail/HTTP_ERROR/HttpData/Parameters/@httpRespondCode"/>
	<!-- Template used to strip root 'join' element -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="count(/join/Message) &gt;=2">
				<xsl:apply-templates select="join/*"/>
			</xsl:when>
			<xsl:otherwise><xsl:copy-of select="if (join) then join/* else *"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="join/Message[Data/HttpHeaders]/Header">
		<xsl:element name="Header">
			<xsl:copy-of select="*"/>
			<xsl:element name="Resource">
				<xsl:value-of select="'results'"/>
			</xsl:element>
			<xsl:if test="starts-with($httpRespondCode,'2')">
				<xsl:element name="Route">
					<xsl:value-of select="'updateGI'"/>
				</xsl:element>
			</xsl:if>
		</xsl:element>
		<xsl:if test="starts-with($httpRespondCode,'2')">
			<xsl:apply-templates select="/join/Message[StoredProcParams]/StoredProcParams"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="join/Message[StoredProcParams]/StoredProcParams">
		<xsl:element name="StoredProcParams">
			<xsl:copy-of select="GI_TREL_SCCTESTINFO_TAB/GI_TREL_SCCTESTINFO_OBJ"/>
			<xsl:call-template name="createHisTestInfo"/>
			<!--<xsl:element name="GI_TREL_COMPINFO_TAB">
				<xsl:element name="GI_TREL_COMPINFO_OBJ"/>
			</xsl:element>-->
			<xsl:element name="returnFromProcedure"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="join/Message[StoredProcParams]"/>
	<!-- copy copy -->
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template name="createHisTestInfo" exclude-result-prefixes="#all">
		<GI_TREL_HISTESTINFO_OBJ>
			<BILLN>
				<xsl:value-of select="$billing"/>
			</BILLN>
			<ORDNUM>
				<xsl:value-of select="$aux"/>
			</ORDNUM>
			<TEST>
				<xsl:value-of select="$testId"/>
			</TEST>
			<DEST>HIS.TEK</DEST>
			<STATUS><xsl:value-of select="$status"/></STATUS>
			<LIS>0</LIS>
			<FLAG>0</FLAG>
			<FlAGSTR>r</FlAGSTR>
			<CORRID>
				<xsl:value-of select="$corrid"/>
			</CORRID>
			<AUXNUM/>
			<PARLIS>0</PARLIS>
			<PARHORDNUM/>
			<!--<ADJUSTFLAGSTR>AT</ADJUSTFLAGSTR>-->
		</GI_TREL_HISTESTINFO_OBJ>
	</xsl:template>
</xsl:stylesheet>
