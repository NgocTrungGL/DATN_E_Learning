pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.bundle.min.js", preload: true
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/esm/index.js"
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.2/dist/js/bootstrap.esm.js"
pin "sortablejs", to: "https://ga.jspm.io/npm:sortablejs@1.15.6/modular/sortable.esm.js"
pin "popper", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/lib/index.js"
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.2/dist/js/bootstrap.esm.js"
pin "chartkick", to: "https://ga.jspm.io/npm:chartkick@5.0.1/dist/chartkick.esm.js"
pin "Chart.bundle", to: "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.4/Chart.bundle.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
pin "animejs" # hoặc pin "animejs", to: "..."
pin_all_from "app/javascript/custom", under: "custom"
# 2. Thư viện xử lý toán học ngày tháng (Date-fns)
pin "date-fns", to: "https://ga.jspm.io/npm:date-fns@2.30.0/index.js"

# 3. Cầu nối (Adapter) để Chart.js hiểu được ngày tháng
pin "chartjs-adapter-date-fns", to: "https://ga.jspm.io/npm:chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.mjs"
