# IKEA Översikt Data PL/SQL

**Översikt** (translated from Swedish) = outline, overview [noun]  
A short description of the main details of a plan, etc.

## Project Summary

It includes the creation and management of a database of a furniture retail store, knowing data about products, offers, orders, customers, sales agents' processing, stock supply and manufacture of parts using materials supplied to the chain.
Real requirements can be observed, in which data collections, simple and dynamic cursors, procedure or function type subprograms, row-level and command-level triggers (mutating) are illustrated, these validate the sales results in a certain period of time, to which current offers, purchasing behavior, employees' work efficiency can be applied or not, profit in relation to production expenses, etc.

## Project Overview

This project involves a furniture company that sells pieces of furniture across several stores located in different locations/addresses. These stores can be either showrooms or order-picking centers, meaning they serve both as points of sale and potential delivery addresses for customer orders. This IKEA replica aims to provide a comprehensive overview of the company's operations, focusing on inventory management, customer orders, and the relationships between various entities within the business model.

### Key Features

1. **Product Sourcing**:
   - The company sells furniture produced in its own factories or by third-party manufacturers.
   - Information about the materials used in the manufacturing process is available only for products manufactured by the company.

2. **Supplier Collaboration**:
   - The company collaborates with suppliers to obtain the raw materials necessary for furniture production.

3. **Sales Agents**:
   - Although the company employs professionals from various fields, only the sales agent is responsible for processing customer orders.
   - Sales agents can work either online or physically at a single branch of the company, meaning that each agent is associated with at most one store.

4. **Product Categorization**:
   - Each piece of furniture belongs to a specific category, allowing products to be identified based on certain characteristics.
   - Materials or raw materials supplied by vendors are used to manufacture the final product.

5. **Offers and Promotions**:
   - Offers can be associated with each piece of furniture within a set period of time.

6. **Inventory Management**:
   - To ensure product validity, the record of furniture within each store is maintained at the stock level.
   - A single stock can be accessed by multiple stores.
   - The relationship between stores, stocks, and furniture helps answer the question: "How many pieces of furniture does a store have distributed at the level of the associated stocks?"
   - This system is designed to track the joint distribution of goods across multiple company locations, enabling regular supply and analysis of the ratio of available to sold products over time.
   - Stocks contain multiple pieces of furniture and are identified by a stock code and the date of supply.

7. **Customer Orders**:
   - Customers can place orders to purchase pieces of furniture.
   - Customers have the option to request delivery of an order to a specified address.
   - Orders are completed through transactions that include payment information.

8. **Customer Identification**:
   - Customers are identified by their purchasing method (physical or online) and legal type (natural or legal person).
   - The order/invoice reflects the rules of practice for furniture and DIY companies.
   - Online customers must provide additional information specific to the company's platform.
   - Physical customers are only required to provide a phone number if they opt for delivery services.
   - The legal type of a customer is not immediately specified but is conceptual. A legal client will have the `nume_firma` field filled in, while a natural person will not.

---

## Content

### Display Material Details and Dimensions for Each Product Category and Order

Display the details of materials and dimensions of a product for each product category and each order that contains it. Only the top 3 most expensive materials (purchased from the supplier) for products in that category will be displayed, along with the orders they are part of. Additionally, there will be an `in out` parameter that counts how many results were returned (number of materials and orders), retaining the count from previous calls to the subroutine.

### Display Store Names and Supply Dates for Furniture Pieces on Offer

Display the names of stores, along with the supply date, for furniture pieces from a given list that are on offer in 2024/2021 and are valid in the store's stock. Additionally, there will be an `out` parameter that stores the distinct address codes of stores that meet the condition for all the given pieces of furniture.

### Display Furniture Pieces with at Least One Associated Raw Material

Display all furniture pieces that have at least one associated raw material, given a list of orders (there may be orders that return `no_materials_associated` for products with associated materials, or `no_materials_associated` if there are products without associated materials in the current order being checked from the list). For the furniture pieces found (those with associated materials in the indicated orders), display the employee who processed the order (exactly one result of this type - `too_many_rows`/`no_data_found`).

### Display Furniture Pieces Containing a Specific Raw Material

Display the furniture pieces that contain a specific raw material (`no_furniture` if no furniture piece contains it). For a purchased quantity of the best-selling furniture piece, display all orders (`no_orders` if there are no orders with the specified quantity of the selected best-selling product) that contain that selected furniture piece (order, number of products in the order, customer, start of product placement, end of product placement, duration of product placement). Additionally, demonstrate the operation of loop cursors with and without subqueries.

### Display Customers Who Placed Orders in Less Than an Hour

Display customers who placed orders in less than an hour, with order values greater than the average for the given month (`invalid_month`). Additionally, return the furniture pieces ordered, at the level of one or more orders, including order details, supply details, and the time interval (from the placement of the first product to the last).

### Update Stock After Inserting a New Order

Display changes after inserting a row into the `adauga_comanda` table (with the condition that the timestamp is greater than those previously entered into the table). This will take the product ID and update its stock in the `detalii_produse` table, knowing that the stock will be updated regardless of whether there are multiple stocks for the same product (to see the possibility of supplying all stocks containing the respective product). Additionally, the stock date will be updated since it has just been modified.

### Modify the Employee Processing a Newly Inserted Order

For an order that has just been inserted into the database, modify the employee processing it only if, up to that point, the employee has high productivity, meaning they have processed more than the average number of orders per employee. Thus, they will be replaced with an employee who has worked less, i.e., someone who has processed a minimal number of orders up to that point (the first employee of this type in ascending order by their ID).

### Log DDL Operations in a Table

Record all successfully executed DDL operations in a `ddl_log` table. If the object is created, dropped, or altered, display its columns.

### Sales Management Package

Consider a package that manages sales, containing 2 procedures and 2 functions, using global variables, cursors, and arrays:
- One array describes the materials of furniture pieces (`tip_material`, `unități`, `preț_producție` (= `preț_unitate` * `unități`)).
- Another array provides information about the orders of given customers that are on offer.

1. **`verifica_oferta_client`**: Checks if a customer has benefited from at least one offer and returns `true` or `false`.
2. **`calcul_total_produse_la_oferta`**: Receives an order and returns the number of products on offer.
3. **`afiseaza_materiale_produse_la_oferta`**: Receives an order and, if the order has benefited from at least one offer (`calcul_total_produse_la_oferta > 0`), populates `t_lista_m` and displays the results (calculates a unit selling price, unit production price, and company profit).
4. **`afiseaza_procent_clienti_cu_oferte`**: Selects from a cursor containing all customers, populates `t_comenzi` (and displays the results), and displays details from `t_comenzi` via `afiseaza_materiale_produse_la_oferta` (practically, the logic of having shared data across multiple functions/subprograms and calling a function within another).

---
