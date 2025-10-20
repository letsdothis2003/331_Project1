# SQL Noir: Solving Mysteries with WideWorldImporters

## Mystery 1 – The Pricey Supplier
**Story:** One supplier has been overcharging compared to others.  

### Steps
- List purchase orders by supplier → establish baseline.  
- Join with order lines and stock items → show unit prices per product.  
- Filter for high-priced items (>100) → reveal suspicious suppliers.  

### Findings
Certain suppliers repeatedly charged well above average — clear signs of overpricing.  

**Time in Video:** ~3–4 minutes  
**T-SQL Concepts:** SELECT, WHERE, JOINs, Window Functions  
**NACE:**  
- Group → Problem Solving (breaking into steps).  
- Individual → Technology (running DBeaver queries, interpreting results).  

---

## Mystery 2 – The Vanishing Customer
**Story:** Some customers placed orders but never received invoices.  

### Steps
- Compare Orders vs Invoices with LEFT JOIN.  
- Filter where InvoiceID IS NULL → find orders with no invoices.  
- Summarize counts per customer.  

### Findings
Tailspin Toys repeatedly placed orders with no invoices — a vanishing act.  

**Time in Video:** ~3–4 minutes  
**T-SQL Concepts:** SELECT, WHERE with NULL, Joins, Aggregates  
**NACE:**  
- Group → Critical Thinking (deciding how to connect tables).  
- Individual → Professionalism (documenting missing invoices).  

---

## Mystery 3 – The Discount Dealer (Loss-Making Sales)
**Story:** A salesperson is causing losses by giving products away too cheaply.  

### Steps
- Check invoice line profits using LineProfit.  
- Filter where LineProfit < 0 → sales at a loss.  
- Group by Salesperson → reveal the biggest offender.  

### Findings
Archer Lamble recorded the most loss-making transactions.  

**Time in Video:** ~3–4 minutes  
**T-SQL Concepts:** SELECT, WHERE, GROUP BY, Aggregates  
**NACE:**  
- Group → Collaboration (peer checking logic).  
- Individual → Equity & Inclusion (evidence-based analysis).  

---

## Mystery 4 – The Unshipped Invoices
**Story:** Were some invoices created without shipments?  

### Steps
- Join Invoices with Stock Transactions.  
- Find invoices without stock transactions.  

### Findings
The query returned no missing shipments. This is still meaningful — it shows system reliability.  

**Time in Video:** ~2–3 minutes  
**T-SQL Concepts:** Joins, WHERE filters  
**NACE:**  
- Group → Communication (explaining “no data” clearly).  
- Individual → Critical Thinking (understanding absence of evidence).  

---

## Mystery 5 – The Suspicious Bulk Orders
**Story:** Certain customers may be abusing the system with massive bulk orders.  

### Steps
- Show all order lines with quantities.  
- Filter for quantities > 300.  
- Summarize totals per customer.  

### Findings
Customers like Manca Hrastovsek and Tailspin Toys placed very large bulk orders, far above normal.  

**Time in Video:** ~3–4 minutes  
**T-SQL Concepts:** SELECT, WHERE, Aggregates, GROUP BY  
**NACE:**  
- Group → Problem Solving (detecting abuse).  
- Individual → Career & Self-Development (applying SQL to fraud detection).  

---

## Use T-SQL Fundamental Connections

---

## Final Reflection & NACE Competencies

### Group Work
- Critical Thinking & Problem Solving – built multi-step queries to uncover hidden issues.  
- Collaboration & Communication – in a group setting, would divide mysteries and explain results clearly.  
- Professionalism – documenting each query and result properly for team review.  

### Individual Work
- Technology – restored the WideWorldImporters database in SQL Server and queried via DBeaver.  
- Equity & Inclusion – analyzed all suppliers/customers objectively using SQL evidence.  
- Career & Self-Development – applied SQL fundamentals to a realistic data-investigation scenario.  

---

## Timing Recap Expectation
- Intro: 1–2 min  
- Mystery 1: 3–4 min  
- Mystery 2: 3–4 min  
- Mystery 3: 3–4 min  
- Mystery 4: 2–3 min  
- Mystery 5: 3–4 min  
- Conclusion: 2–3 min  


