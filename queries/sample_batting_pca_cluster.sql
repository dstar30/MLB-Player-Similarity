select bp.*, p.key_mlbam mlb_id, p.name_first, p.name_last, p.primary_position_txt 
from baseball.dbo.batting_pca bp
join baseball.dbo.players p
	on bp.key_fangraphs = p.key_fangraphs
where season >= 2017