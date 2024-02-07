<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:r="http://www.oxygenxml.com/ns/report" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    
    <xsl:output encoding="UTF-8" method="xml"/>
    <xsl:output indent="yes"/>
    
    <xsl:template match="@* | element()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:choose>
            <xsl:when test="matches(., '\p{IsEthiopic}')">
                <xsl:value-of select="replace(normalize-space(.), '᎓',  '፡' ) =&gt; replace('([rv])(\)\s+\()([abc]\))',  '$1$3' )                 =&gt; replace(' ፡', '፡ ')                  =&gt; replace('(\S{2})','​$1')                  =&gt;  replace('(​(፡))','$2')                 =&gt;  replace('(​$)','')  "/>
        </xsl:when>
            <xsl:when test="matches(., '\p{IsArabic}')">
                <xsl:value-of select="replace(normalize-space(.), ',',  '،' ) =&gt;  replace(';', '؛')  "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
