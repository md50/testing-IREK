<!-- $Id: prepRequest.xslt 11817 2022-05-16 10:30:19Z rafalpa $  -->
<xsl:stylesheet version="2.0" exclude-result-prefixes="#all"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fun="http://interfaces_function.com">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Parameters -->
	<xsl:param name="externalURL">${externalURL}</xsl:param>
	<xsl:variable name="token" as="xs:string">${!DICT.LABTEK_B}</xsl:variable>
	<xsl:variable name="tz" select="format-dateTime(current-dateTime(),'[Z0001]')"/>
	<xsl:variable name="obrLevel" select="//Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel"/>
	<!-- Main match -->
	<xsl:template match="/join">
		<xsl:element name="Message">
			<xsl:attribute name="contentType">application/json;charset=UTF-8</xsl:attribute>
			<xsl:attribute name="method">POST</xsl:attribute>
			<xsl:attribute name="resource" select="$externalURL"/>
			<xsl:attribute name="server_tz" select="$tz"/>
			<xsl:element name="Header">
				<xsl:element name="Instance">JSON</xsl:element>
				<xsl:element name="Source">JSON</xsl:element>
				<xsl:element name="Route"><xsl:value-of select="if (Message/SQLoutput/rows/row) then 'EXT_SYS' else 'MISSING_GI'"/></xsl:element>
				<xsl:element name="Authorization">Bearer <xsl:value-of select="$token"/></xsl:element>
			</xsl:element>
			<xsl:element name="Data">
				<xsl:element name="root">
					<xsl:copy-of select="fun:element(fun:dateTimeZone(Message/Event/msg/sendDate),'timestamp')"/>
					<xsl:copy-of select="fun:element(Message/Event/msg/destMsgId,'transactionId')"/>
					<xsl:copy-of select="fun:element(Message/Event/msg/eventCode = 'ORDER_STATUS_RESEND','resend')"/>
					<xsl:call-template name="patient"/>
					<xsl:call-template name="order"/>
				</xsl:element>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<!-- Templates -->
	<xsl:template name="patient">
		<patient class="object">
			<xsl:copy-of select="fun:element(Message/Event/msg/attributes[name='MRN']/value,'patientId')"/>
		</patient>
	</xsl:template>
	<xsl:template name="order">
		<order class="object">
			<xsl:copy-of select="fun:element(($obrLevel/spmLevel/sacLevel/sac/tubeBarcode[@source='externalTubeId']/text(),$obrLevel/spmLevel/spm/specimenBarcode/text(),Message/Event/msg/attributes[name='EXTID']/value/text(),Message/Event/msg/attributes[name='BARCODE']/value/text())[1],'sampleId')"/>
			<xsl:copy-of select="fun:element(Message/SQLoutput/rows/row/GI_HIS_TEST,'testId')"/>
			<xsl:copy-of select="fun:element(Message/SQLoutput/rows/row/GI_HIS_CORRELATION_ID,'hisNumber')"/>
			<xsl:choose>
				<xsl:when test="Message/Event/msg/eventCode = ('TUBE_PROCESSED','TEST_PROCESSED')">
					<xsl:copy-of select="fun:element(Message/Event/msg/attributes[name='ACTION_CODE']/value,'currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(Message/Event/msg/attributes[name='CREATEDON']/concat(substring(value,1,10),'T',substring(value,12),substring(Message/Event/msg/sendDate,24))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/eventCode = 'SPECIMEN_PROTOCOL_RERUN'">
					<xsl:copy-of select="fun:element('!SPCPROTRERUN','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(Message/Event/msg/attributes[name='CREATEDON']/concat(substring(value,1,10),'T',substring(value,12),substring(Message/Event/msg/sendDate,24))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/eventCode = 'SPECIMEN_PROTOCOL_UNDORERUN'">
					<xsl:copy-of select="fun:element('!SPCPROTUNRER','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(Message/Event/msg/attributes[name='CREATEDON']/concat(substring(value,1,10),'T',substring(value,12),substring(Message/Event/msg/sendDate,24))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/eventCode = 'TEST_PROTOCOL_RERUN'">
					<xsl:copy-of select="fun:element('!TSTPROTRERUN','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(Message/Event/msg/attributes[name='CREATEDON']/concat(substring(value,1,10),'T',substring(value,12),substring(Message/Event/msg/sendDate,24))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/eventCode = 'TEST_PROTOCOL_UNDORERUN'">
					<xsl:copy-of select="fun:element('!TSTPROTUNRER','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(Message/Event/msg/attributes[name='CREATEDON']/concat(substring(value,1,10),'T',substring(value,12),substring(Message/Event/msg/sendDate,24))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/eventCode = 'SPECIMEN_COLLECTED'">
					<xsl:copy-of select="fun:element('!COLLECTED','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(min(Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/spmLevel/spm/xs:dateTime(if (string(collectedDateTime/@odt)) then collectedDateTime/@odt else collectedDateTime))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/eventCode = 'SPECIMEN_RECEIVED'">
					<xsl:copy-of select="fun:element('!RECEIVED','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(min(Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/spmLevel/sacLevel/sac/xs:dateTime(if (string(receivedDate/@odt)) then receivedDate/@odt else receivedDate))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/attributes[name='TEST_STATUS']/value = 'Cancelled'">
					<xsl:copy-of select="fun:element('!CANCELED','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(if (string(Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/obr/cancellationDate/@odt)) then Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/obr/cancellationDate/@odt else Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/obr/cancellationDate/text()),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Event/msg/attributes[name='TEST_STATUS']/value = 'Final'">
					<xsl:copy-of select="fun:element('!SIGNED','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(max(Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/obxLevel/obx/xs:dateTime(verificationDateTime[text()]))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="*:GetProcessingHistoryResponse/*:processingHistory/*:historyItems">
					<xsl:for-each select="*:GetProcessingHistoryResponse/*:processingHistory/*:historyItems[*:ownerType = 'T' or *:topPanelTestCode = /join/Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/obr/testId]">
						<xsl:sort select="*:actionId" order="descending" data-type="number"/>
						<xsl:if test="position() = 1"><xsl:apply-templates select="."/></xsl:if>
					</xsl:for-each>
				</xsl:when>
				<xsl:when test="Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/spmLevel/sacLevel/sac/receivedDate/text()">
					<xsl:copy-of select="fun:element('!RECEIVED','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(min(Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/spmLevel/sacLevel/sac/xs:dateTime(if (string(receivedDate/@odt)) then receivedDate/@odt else receivedDate))),'actionDT')"/>
				</xsl:when>
				<xsl:when test="Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/spmLevel/spm/collectedDateTime/text()">
					<xsl:copy-of select="fun:element('!COLLECTED','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(min(Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/spmLevel/spm/xs:dateTime(if (string(collectedDateTime/@odt)) then collectedDateTime/@odt else collectedDateTime))),'actionDT')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="fun:element('!ORDERED','currentTestStatusId')"/>
					<xsl:copy-of select="fun:element(fun:dateTimeZone(SQLoutput/rows/row/gi_his_create),'actionDT')"/>
				</xsl:otherwise>
			</xsl:choose>
		</order>
	</xsl:template>
	<xsl:template match="*:historyItems">
		<xsl:copy-of select="fun:element(*:actionCode,'currentTestStatusId')"/>
		<xsl:copy-of select="fun:element(fun:dateTimeZone(*:actionDate),'actionDT')"/>
	</xsl:template>
	<xsl:function name="fun:element">
		<xsl:param name="source"/>
		<xsl:param name="targetName"/>
		<xsl:if test="string($source)">
			<xsl:element name="{$targetName}">
				<xsl:value-of select="$source"/>
			</xsl:element>
		</xsl:if>
	</xsl:function>
	<xsl:function name="fun:dateTimeZone">
		<xsl:param name="source"/>
		<xsl:value-of select="if (string-length(xs:string($source))=25) then $source else concat(substring(xs:string($source),1,19), $tz)"/>
	</xsl:function>
</xsl:stylesheet>