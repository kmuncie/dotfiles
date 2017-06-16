" Increase length of commit summary guide
syn clear gitcommitSummary
syn match gitcommitSummary "^.\{0,69\}" contained containedin=gitcommitFirstLine nextgroup=gitcommitOverflow contains=@Spell
