// Tab switching for auth page
// Paste this into app/javascript/auth.js or inline via a content_for block

document.addEventListener('DOMContentLoaded', () => {
  const tabs = document.querySelectorAll('.tab-btn');
  const contents = document.querySelectorAll('.tab-content');

  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      tabs.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      contents.forEach(c => c.classList.add('hidden'));
      const target = document.getElementById('tab-content-' + btn.dataset.tab);
      if (target) target.classList.remove('hidden');
    });
  });

  // Password toggle visibility
  document.querySelectorAll('.toggle-pw').forEach(btn => {
    btn.addEventListener('click', () => {
      const input = document.getElementById(btn.dataset.target);
      if (!input) return;
      const isHidden = input.type === 'password';
      input.type = isHidden ? 'text' : 'password';
      const icon = btn.querySelector('i');
      if (icon) {
        icon.classList.toggle('bi-eye-slash', !isHidden);
        icon.classList.toggle('bi-eye', isHidden);
      }
    });
  });
});
