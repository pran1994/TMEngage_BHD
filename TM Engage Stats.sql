declare @Subscriptions table (
	id int identity(1,1),
	SubscriptionName nvarchar(255) null,
	SubscriptionId nvarchar(255) null,
	SFFieldName nvarchar(255) null
)

declare @Results table (
	SubscriptionId nvarchar(255) null,
	SubscriptionName nvarchar(255) null,
	[Frequency In File] int null,
	[Records Updated] int null
)

insert @Subscriptions(SubscriptionName,SubscriptionId,SFFieldName)
select SubscriptionName,SubscriptionId,MarketingPrefFlag from TMEngage.Subscriptions

declare @recordcnt int = 1
declare @subscriptionid nvarchar(255)
declare @subscriptionname nvarchar(255)
declare @sffieldname nvarchar(255)
declare @tsql nvarchar(4000) 
DECLARE @outputParam INT

while @recordcnt <= (select max(id) from @Subscriptions)
begin
select @subscriptionid=SubscriptionId,@subscriptionname=trim(subscriptionname),@sffieldname=SFFieldName from @Subscriptions where id = @recordcnt

select @tsql = N'Select @count_out = count(*)  from bulkv2ExportFiles.TMEngageMarketingPrefs_All where ' + @sffieldname + ' is not null group by ' + @sffieldname
exec sp_executesql @tsql, N'@count_out int out', @outputParam OUT;

insert @Results(SubscriptionId,SubscriptionName,[Records Updated])
select @subscriptionid,sdu_tools.AsciiOnly(@subscriptionname,'',1),@outputParam

set @recordcnt +=1
end

drop table if exists #tmp_FileCounts

select SubscriptionId,count(*) as [Frequency in file]
into #tmp_FileCounts
from TMEngage.SubscriptionData
group by SubscriptionId

update @Results
	set [Frequency In File] = f.[Frequency in file]
from @Results r
inner join #tmp_FileCounts f on 
	r.SubscriptionId = f.SubscriptionId

select * from @Results


--Unmatched
select distinct s.cust_name_id,s.Email
from TMEngage.SubscriptionData s
left join TMEngage.SFMarketingPrefs m on
	s.cust_name_id = m.Archtics_contact_id__c
left join TMEngage.SFMarketingPrefs m2 on 
	s.Email = m2.Email
where m.Archtics_contact_id__c is null and m2.Email is null