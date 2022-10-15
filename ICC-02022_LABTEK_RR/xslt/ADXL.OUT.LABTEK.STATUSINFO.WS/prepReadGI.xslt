<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: prepReadGI.xslt 11722 2022-04-26 12:56:50Z jzajdel $ -->
<xsl:stylesheet version="2.0" exclude-result-prefixes="#all"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:mom="http://mom.scc.com/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
	<xsl:strip-space elements="*"/>
	<xsl:template match="node() | @*"><xsl:copy copy-namespaces="no"><xsl:apply-templates select="node() | @*"/></xsl:copy></xsl:template>
	<xsl:variable name="route" select="if (not(string(/mom:onMessage/msg/attributes[name='TEST']/value))) then 'MISSING_TEST' else if (contains(/mom:onMessage/msg/attributes[name='REPORTABLE_TEST']/value,',')) then 'RESPONSE' else 'READ_GI'"/>
	<xsl:template match="/mom:onMessage">
		<xsl:choose>
			<xsl:when test="//obrLevel/obr/reportable='false'">
				<xsl:element name="skip">
					<xsl:attribute name="status" select="'9'"/>
					<xsl:attribute name="details" select="concat('Message processing has been skipped. Test [',//obrLevel/obr/testId,'] is not reportable.')"/>
				</xsl:element>
			</xsl:when>
			<xsl:when test="msg/msgText/Message">
				<xsl:apply-templates select="msg/msgText/Message">
					<xsl:with-param name="attrAndSuch" select="msg/* except msg/msgText" tunnel="yes"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="msg/attributes[name = 'REPORTABLE_TEST'] and not(string(msg/attributes[name = 'REPORTABLE_TEST']/value))">
				<xsl:element name="skip">
					<xsl:attribute name="status">9</xsl:attribute>
					<xsl:attribute name="details">Message processing has been skipped. All related tests are not reportable.</xsl:attribute>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="Message">
					<xsl:element name="Header">
						<xsl:element name="Action"><xsl:value-of select="msg/eventCode"/></xsl:element>
						<xsl:element name="Source"><xsl:value-of select="msg/sender"/></xsl:element>
						<xsl:element name="Date"><xsl:value-of select="current-date()"/></xsl:element>
						<xsl:element name="Time"><xsl:value-of select="current-time()"/></xsl:element>
						<xsl:element name="Status">OK</xsl:element>
						<xsl:element name="Route"><xsl:value-of select="$route"/></xsl:element>
					</xsl:element>
					<xsl:element name="Data"/>
					<xsl:element name="Event">
						<msg>
							<xsl:if test="not(msg/attributes[name='BILLING'])">
								<attributes>
									<name>BILLING</name>
									<value><xsl:value-of select="/*:onMessage/msg/attributes[name='BARCODE']/value"/></value>
								</attributes>
							</xsl:if>
							<xsl:apply-templates select="msg/* except msg/msgText"/>
						</msg>
					</xsl:element>
					<xsl:if test="msg/attributes[name='REPORTABLE_TEST'] and not(contains(msg/attributes[name='REPORTABLE_TEST']/value,',')) or not(msg/attributes[name='REPORTABLE_TEST'])">
						<xsl:element name="SQLoutput"/>
					</xsl:if>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="attributes[name = 'TEST' and ../attributes[name = 'REPORTABLE_TEST'] and $route = 'READ_GI']/value/text()"><xsl:value-of select="../../../attributes[name = 'REPORTABLE_TEST']/normalize-space(value)"/></xsl:template>
	<xsl:template match="Header">
		<xsl:copy>
			<xsl:apply-templates select="node() | @*"/>
			<xsl:element name="Route">READ_GI</xsl:element>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="Message/Header/Message"/>
	<xsl:template match="Message">
		<xsl:copy>
			<xsl:apply-templates select="node() | @*"/>
			<xsl:element name="SQLoutput"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="Message/Event">
		<xsl:param name="attrAndSuch" tunnel="yes"/>
		<xsl:copy><msg><xsl:copy-of select="$attrAndSuch" copy-namespaces="no"/></msg></xsl:copy>
	</xsl:template>
</xsl:stylesheet>