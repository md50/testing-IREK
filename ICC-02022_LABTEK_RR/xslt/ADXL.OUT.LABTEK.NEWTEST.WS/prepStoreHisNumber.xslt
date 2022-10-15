<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: prepStoreHisNumber.xslt 11100 2022-01-14 16:49:00Z rafalpa $  -->
<!-- ADXL.OUT.LABTEK.NEWTEST.WS store HIS# in GI -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mom="http://mom.scc.com/" xmlns:rec="http://mom.scc.com/" xmlns:fun="http://www.softcomputer.com/MU2functionsAS" xmlns:saxon="http://saxon.sf.net/">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<xsl:variable name="root" select="join"/>
	<xsl:variable name="extractedMsg" select="if(//msgText/text()) then saxon:parse(//msgText)/* else ''"/>
	<xsl:variable name="date" select="$extractedMsg//Header/Date"/>
	<xsl:variable name="event" select="/join/*:onMessage/msg/attributes[name='EVENT']/value"/>
	<xsl:variable name="billing" select="/join/*:onMessage/msg/attributes[name='BILLING']/value"/>
	<xsl:variable name="testId" select="/join/*:onMessage/msg/attributes[name='TEST']/value"/>
	<xsl:variable name="order" select="/join/*:onMessage/msg/attributes[name='ORDER']/value"/>
	<xsl:variable name="seq" select="/join/*:onMessage/msg/attributes[name='SEQ']/value"/>
	<xsl:variable name="ext" select="/join/*:onMessage/msg/attributes[name='EXT'][1]/value"/>
	<xsl:variable name="currendDate" select="substring(translate($root/*:onMessage/msg/sendDate, 'T', ' '),1,23)"/>
	<xsl:variable name="aux" select="/join/*:SubmitOrderResponse/*:SubmitOrderResult/*:UpdatedOrders/*:AuxiliaryOrder"/>
	<xsl:template match="/">
		<xsl:apply-templates select="saxon:parse(//msgText)/*"/>
	</xsl:template>
	<xsl:template match="Message/Header">
		<xsl:element name="Header">
			<xsl:copy-of select="*"/>
			<xsl:element name="Route">
				<xsl:value-of select="'updateGI'"/>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template match="Message/StoredProcParams" exclude-result-prefixes="#all">
		<xsl:element name="StoredProcParams">
			<xsl:element name="GET_ALL">0</xsl:element>
			<OrderNumber>
				<xsl:value-of select="$order"/>
			</OrderNumber>
			<TestId>
				<xsl:value-of select="$testId"/>
			</TestId>
			<TestExtension>
				<xsl:value-of select="$ext"/>
			</TestExtension>
			<SequenceNumber>
				<xsl:value-of select="$seq"/>
			</SequenceNumber>
			<SystemId>
				<xsl:value-of select="$root/*:onMessage/msg/senderCode"/>
			</SystemId>
			<DestId>
				<xsl:value-of select="'HIS.TEK'"/>
			</DestId>
			<Billing>
				<xsl:value-of select="$billing"/>
			</Billing>
			<xsl:copy-of select="GI_TREL_SCCTESTINFO_OBJ"/>
			<!--<xsl:call-template name="createCompInfoTab"/>-->
			<xsl:call-template name="createHisTestInfo"/>
			<xsl:element name="Date">
				<xsl:value-of select="$date"/>
			</xsl:element>
			<xsl:element name="MomEvent">
				<xsl:value-of select="$event"/>
			</xsl:element>
			<xsl:element name="CurrentDate">
				<xsl:value-of select="$currendDate"/>
			</xsl:element>
		</xsl:element>
		<xsl:element name="ReportableComponents"/>
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
			<LIS>
				<xsl:value-of select="$extractedMsg//RelatedOrders/GI_TREL_HISTESTINFO_OBJ/LIS"/>
			</LIS>
			<FLAG>0</FLAG>
			<CORRID>0</CORRID>
			<AUXNUM/>
			<PARLIS>0</PARLIS>
			<PARHORDNUM/>
			<ADJUSTFLAGSTR>A</ADJUSTFLAGSTR>
		</GI_TREL_HISTESTINFO_OBJ>
	</xsl:template>
	<xsl:template name="createCompInfoTab" exclude-result-prefixes="#all">
		<!--<GI_TREL_COMPINFO_TAB>
			<xsl:for-each select="$extractedMsg//obxLevel/obx[
						history = 'false' and observationId != 'CANNEDMESSAGE' and obxType='Result']">
				<GI_TREL_COMPINFO_OBJ>
					<TEST>
						<xsl:value-of select="observationId"/>
					</TEST>
					<SECONDARYID>
						<xsl:choose>
							<xsl:when test="obxType = 'Result' and (section = 'ResultFields' or section = 'TableSection') and fun:getTestHeader(observationCode, ../../obxLevel[obx[obxType = 'TestInfo' and section = 'TestHeader' and observationCode = observationId and observationSecId/text()]]/obx)/observationSecId/text()">
								<xsl:value-of select="fun:getTestHeader(observationCode, ../../obxLevel[obx[obxType = 'TestInfo' and section = 'TestHeader' and observationCode = observationId and observationSecId/text()]]/obx)/observationSecId"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="observationCode"/>
							</xsl:otherwise>
						</xsl:choose>
					</SECONDARYID>
					<MODIFDT>
						<xsl:value-of select="$currendDate"/>
					</MODIFDT>
					<SENDDT>
						<xsl:value-of select="$currendDate"/>
					</SENDDT>
					<FLAG>0</FLAG>
				</GI_TREL_COMPINFO_OBJ>
			</xsl:for-each>
		</GI_TREL_COMPINFO_TAB>-->
		<GI_TREL_COMPINFO_TAB>
			<GI_TREL_COMPINFO_OBJ/>
		</GI_TREL_COMPINFO_TAB>
	</xsl:template>
	<xsl:template match="Message/RelatedOrders"/>
	<xsl:function name="fun:getTestHeader" as="item()*">
		<xsl:param name="testName"/>
		<xsl:param name="testHeaderNodes"/>
		<xsl:copy-of select="$testHeaderNodes[observationCode = $testName][1]"/>
	</xsl:function>
	<!-- copy copy -->
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
