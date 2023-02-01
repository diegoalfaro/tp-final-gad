SELECT
	(artwork_a),
	(artwork_b),
	(1 - (artwork_a.pattern % artwork_b.pattern) * 100) || '%' pctg
FROM artwork artwork_a, artwork artwork_b
WHERE artwork_a.id > artwork_b.id
ORDER BY artwork_a.pattern % artwork_b.pattern ASC;
