" Increase length of commit summary guide
syn clear gitcommitSummary
syn match gitcommitSummary ".*\%<74v" contained containedin=gitcommitFirstLine nextgroup=gitcommitOverflow contains=@Spell
