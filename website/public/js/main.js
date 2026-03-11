// Navigation scroll effect
const nav = document.getElementById('nav');
if (nav) {
  window.addEventListener('scroll', () => {
    nav.classList.toggle('scrolled', window.scrollY > 40);
  });
}

// Mobile menu toggle
const toggle = document.getElementById('nav-toggle');
const links = document.getElementById('nav-links');
if (toggle && links) {
  toggle.addEventListener('click', () => {
    links.classList.toggle('open');
  });
  links.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => links.classList.remove('open'));
  });
}

// FAQ accordion
document.querySelectorAll('.faq-q').forEach(btn => {
  btn.addEventListener('click', () => {
    const item = btn.parentElement;
    const wasOpen = item.classList.contains('open');
    document.querySelectorAll('.faq-item.open').forEach(i => i.classList.remove('open'));
    if (!wasOpen) item.classList.add('open');
  });
});

// Scroll animations — staggered
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
    }
  });
}, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

document.querySelectorAll('.feature-card, .calc-card, .price-card, .faq-item, .cta-inner, .testimonial-card, .why-card, .loss-calc-inner, .email-inner').forEach((el, i) => {
  el.classList.add('animate-in');
  el.style.transitionDelay = (i % 6) * 0.08 + 's';
  observer.observe(el);
});

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', (e) => {
    const href = anchor.getAttribute('href');
    if (href === '#') return;
    const target = document.querySelector(href);
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
});

// --- Loss Calculator ---
const lcSavings = document.getElementById('lc-savings');
const lcMer = document.getElementById('lc-mer');
const lcYears = document.getElementById('lc-years');
const lcResult = document.getElementById('lc-result');
const lcMerVal = document.getElementById('lc-mer-val');
const lcResultYears = document.getElementById('lc-result-years');

function updateLossCalc() {
  if (!lcSavings || !lcMer || !lcYears) return;

  const savings = parseFloat(lcSavings.value) || 0;
  const mer = parseFloat(lcMer.value) / 100;
  const years = parseInt(lcYears.value) || 30;
  const lowMer = 0.002; // 0.20% ETF
  const grossReturn = 0.07;

  const lowBalance = savings * Math.pow(1 + (grossReturn - lowMer), years);
  const highBalance = savings * Math.pow(1 + (grossReturn - mer), years);
  const loss = Math.round(lowBalance - highBalance);

  if (lcResult) lcResult.textContent = '$' + Math.abs(loss).toLocaleString();
  if (lcMerVal) lcMerVal.textContent = (mer * 100).toFixed(1) + '%';
  if (lcResultYears) lcResultYears.textContent = years;
}

if (lcSavings) {
  [lcSavings, lcMer, lcYears].forEach(el => {
    el.addEventListener('input', updateLossCalc);
  });
  updateLossCalc();
}

// --- Pricing Toggle ---
const pricingToggle = document.getElementById('pricing-toggle');
if (pricingToggle) {
  let isAnnual = false;

  pricingToggle.addEventListener('click', () => {
    isAnnual = !isAnnual;
    pricingToggle.classList.toggle('active', isAnnual);

    document.querySelectorAll('.price-val').forEach(el => {
      el.textContent = isAnnual ? el.dataset.annual : el.dataset.monthly;
    });
    document.querySelectorAll('.price-per').forEach(el => {
      el.textContent = isAnnual ? el.dataset.annual : el.dataset.monthly;
    });
    document.querySelectorAll('.price-desc-val').forEach(el => {
      el.textContent = isAnnual ? el.dataset.annual : el.dataset.monthly;
    });
  });
}

// --- Email Form ---
window.handleEmailSubmit = function(e) {
  e.preventDefault();
  const input = document.getElementById('email-input');
  const form = document.getElementById('email-form');
  if (!input || !form) return;

  // In production, this would submit to your backend/email service
  const email = input.value;
  form.innerHTML = '<div class="email-success" style="display:block">Thanks! Check your inbox for the RRSP vs TFSA cheat sheet.</div>';
};

// --- Animated number counter for hero stat ---
function animateValue(el, start, end, duration) {
  const range = end - start;
  const startTime = performance.now();

  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3); // ease-out cubic
    const current = start + range * eased;

    if (el.dataset.format === 'dollar') {
      el.textContent = '$' + Math.round(current).toLocaleString();
    } else {
      el.textContent = Math.round(current).toLocaleString();
    }

    if (progress < 1) {
      requestAnimationFrame(update);
    }
  }

  requestAnimationFrame(update);
}

// Counter animation for the loss calc result on scroll
const lossResultObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      updateLossCalc();
      lossResultObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.5 });

const lossSection = document.querySelector('.loss-calc');
if (lossSection) lossResultObserver.observe(lossSection);
