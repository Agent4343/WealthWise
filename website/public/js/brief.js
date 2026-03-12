/* ============================================
   WealthWise — AI Weekly Brief Preview Logic
   ============================================ */

(function () {
  const provincialBaseRates = {
    AB: 0.10, BC: 0.0506, MB: 0.108, NB: 0.094,
    NL: 0.087, NS: 0.0879, NT: 0.059, NU: 0.04,
    ON: 0.0505, PE: 0.098, QC: 0.14, SK: 0.105,
    YT: 0.064
  };

  const provinceNames = {
    AB: 'Alberta', BC: 'British Columbia', MB: 'Manitoba', NB: 'New Brunswick',
    NL: 'Newfoundland', NS: 'Nova Scotia', NT: 'Northwest Territories',
    NU: 'Nunavut', ON: 'Ontario', PE: 'PEI', QC: 'Quebec',
    SK: 'Saskatchewan', YT: 'Yukon'
  };

  const federalBrackets = [
    { upper: 57375, rate: 0.15 },
    { upper: 114750, rate: 0.205 },
    { upper: 158468, rate: 0.26 },
    { upper: 220000, rate: 0.29 },
    { upper: Infinity, rate: 0.33 }
  ];

  function federalMarginalRate(income) {
    for (let i = federalBrackets.length - 1; i >= 0; i--) {
      const lower = i === 0 ? 0 : federalBrackets[i - 1].upper;
      if (income > lower) return federalBrackets[i].rate;
    }
    return federalBrackets[0].rate;
  }

  function bracketLabel(income) {
    const rate = federalMarginalRate(income);
    return (rate * 100).toFixed(1) + '%';
  }

  function fmt(n) {
    return '$' + Math.round(n).toLocaleString('en-CA');
  }

  function pct(n) {
    return (n * 100).toFixed(1) + '%';
  }

  function updateBrief() {
    const province = document.getElementById('brief-province').value;
    const income = parseFloat(document.getElementById('brief-income').value) || 0;
    const rrspUsed = parseFloat(document.getElementById('brief-rrsp').value) || 0;
    const tfsaUsed = parseFloat(document.getElementById('brief-tfsa').value) || 0;

    const tfsaMax = 109000;
    const rrspMax = Math.min(income * 0.18, 33810);
    const tfsaRemaining = Math.max(0, tfsaMax - tfsaUsed);
    const rrspRemaining = Math.max(0, rrspMax - rrspUsed);
    const tfsaPct = tfsaMax > 0 ? (tfsaUsed / tfsaMax) : 0;
    const rrspPct = rrspMax > 0 ? (rrspUsed / rrspMax) : 0;

    const fedRate = federalMarginalRate(income);
    const provRate = provincialBaseRates[province] || 0.05;
    const combinedRate = fedRate + provRate;

    const suggestedContribution = Math.min(5000, rrspRemaining);
    const taxSavings = Math.round(suggestedContribution * combinedRate);

    const provName = provinceNames[province] || province;

    // Section 1
    const s1 = document.getElementById('brief-s1-content');
    if (s1) {
      const moneyScore = Math.min(100, Math.round(
        (Math.min(1, tfsaPct) * 15) +
        (Math.min(1, rrspPct) * 15) +
        55 // baseline for other factors
      ));
      const grade = moneyScore >= 85 ? 'Excellent' : moneyScore >= 70 ? 'Great' : moneyScore >= 55 ? 'Good' : moneyScore >= 40 ? 'Fair' : 'Needs Work';
      s1.textContent = `Your Money Score is ${moneyScore} (${grade}). You're in the ${pct(combinedRate)} combined marginal bracket in ${provName}. ` +
        (rrspRemaining > 0
          ? `This week's focus: your RRSP deadline is in 12 days. You have ${fmt(rrspRemaining)} in estimated RRSP room — even a small contribution will lower your 2025 tax bill.`
          : `Your RRSP room is fully used — great work! Focus on maximizing your remaining ${fmt(tfsaRemaining)} in TFSA room for tax-free growth.`);
    }

    // Section 3 — accounts
    const baTfsa = document.getElementById('ba-tfsa');
    const baTfsaBar = document.getElementById('ba-tfsa-bar');
    const baTfsaDetail = document.getElementById('ba-tfsa-detail');
    if (baTfsa) baTfsa.textContent = fmt(tfsaRemaining);
    if (baTfsaBar) baTfsaBar.style.width = pct(tfsaPct);
    if (baTfsaDetail) baTfsaDetail.textContent = `${fmt(tfsaUsed)} of ${fmt(tfsaMax)} used (${pct(tfsaPct)})`;

    const baRrsp = document.getElementById('ba-rrsp');
    const baRrspBar = document.getElementById('ba-rrsp-bar');
    const baRrspDetail = document.getElementById('ba-rrsp-detail');
    if (baRrsp) baRrsp.textContent = fmt(rrspRemaining);
    if (baRrspBar) baRrspBar.style.width = pct(rrspPct);
    if (baRrspDetail) baRrspDetail.textContent = `${fmt(rrspUsed)} of ${fmt(Math.round(rrspMax))} used (${pct(rrspPct)})`;

    // Section 4
    const s4 = document.getElementById('brief-s4-content');
    if (s4) {
      if (rrspRemaining > 0 && suggestedContribution > 0) {
        s4.textContent = `At your income of ${fmt(income)}, you're in the ${bracketLabel(income)} federal bracket (${pct(combinedRate)} combined with ${provName}). Every dollar you contribute to your RRSP saves you ${(combinedRate * 100).toFixed(1)}\u00A2 in combined tax. Contributing ${fmt(suggestedContribution)} before the March 2, 2026 deadline would save you ${fmt(taxSavings)} on your 2025 return. That refund \u2192 TFSA = the 1-2 Punch.`;
      } else {
        s4.textContent = `At your income of ${fmt(income)}, you're in the ${pct(combinedRate)} combined bracket in ${provName}. Your RRSP room is used up — well done. Focus on your TFSA: you have ${fmt(tfsaRemaining)} remaining. Every dollar inside grows completely tax-free. At 7% annual return, ${fmt(tfsaRemaining)} grows to ${fmt(tfsaRemaining * Math.pow(1.07, 20))} in 20 years — all tax-free.`;
      }
    }

    // Section 5 — action item
    const actionTitle = document.getElementById('brief-action-title');
    const actionDetail = document.getElementById('brief-action-detail');
    if (actionTitle && actionDetail) {
      if (rrspRemaining > 0 && suggestedContribution > 0) {
        actionTitle.textContent = `Transfer ${fmt(suggestedContribution)} to your RRSP before March 2, 2026`;
        actionDetail.textContent = `This saves you an estimated ${fmt(taxSavings)} in taxes. When you get the refund, invest it in your TFSA for tax-free growth. Total tax-sheltered: ${fmt(suggestedContribution + taxSavings)}. Time needed: 5 minutes via online banking.`;
      } else {
        actionTitle.textContent = `Set up automatic monthly TFSA contribution`;
        const monthlyAmount = Math.min(583, Math.round(tfsaRemaining / 12));
        actionTitle.textContent = `Set up a ${fmt(monthlyAmount)}/month automatic TFSA transfer`;
        actionDetail.textContent = `You have ${fmt(tfsaRemaining)} in TFSA room. Automating ${fmt(monthlyAmount)}/month fills your room by year-end. At 7% annual return, this grows tax-free. Set it up once, forget about it. Time needed: 5 minutes via online banking.`;
      }
    }
  }

  // Bind inputs
  ['brief-province', 'brief-income', 'brief-rrsp', 'brief-tfsa'].forEach(function (id) {
    const el = document.getElementById(id);
    if (el) {
      el.addEventListener('input', updateBrief);
      el.addEventListener('change', updateBrief);
    }
  });

  // Initial render
  updateBrief();
})();
