CREATE OR REPLACE PACKAGE pkg_coffee_mgmt AS
    -- Function to calculate cherry price based on grade and weight
    FUNCTION calculate_price(p_weight IN NUMBER, p_grade IN CHAR) RETURN NUMBER;

    -- Procedure to register delivery and automatically schedule a payout
    PROCEDURE register_delivery(
        p_farmer_id IN NUMBER,
        p_batch_id IN NUMBER,
        p_weight IN NUMBER,
        p_grade IN CHAR
    );
END pkg_coffee_mgmt;

/


CREATE OR REPLACE PACKAGE BODY pkg_coffee_mgmt AS

    FUNCTION calculate_price(p_weight IN NUMBER, p_grade IN CHAR) RETURN NUMBER IS
        v_price_per_kg NUMBER;
    BEGIN
        -- Standardize pricing models per grade in RWF
        IF p_grade = 'A' THEN
            v_price_per_kg := 410;
        ELSIF p_grade = 'B' THEN
            v_price_per_kg := 320;
        ELSE
            v_price_per_kg := 200;
        END IF;

        RETURN p_weight * v_price_per_kg;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END calculate_price;

    PROCEDURE register_delivery(
        p_farmer_id IN NUMBER,
        p_batch_id IN NUMBER,
        p_weight IN NUMBER,
        p_grade IN CHAR
    ) IS
        v_delivery_id NUMBER;
        v_calculated_payout NUMBER;
    BEGIN
        -- Step 1: Insert Delivery
        INSERT INTO Deliveries (Farmer_ID, Batch_ID, Weight_Kg, Quality_Grade)
        VALUES (p_farmer_id, p_batch_id, p_weight, p_grade)
        RETURNING Delivery_ID INTO v_delivery_id;

        -- Step 2: Calculate payment amount using our package function
        v_calculated_payout := calculate_price(p_weight, p_grade);

        -- Step 3: Insert Pending Payout Record
        INSERT INTO Payouts (Delivery_ID, Amount_RWF, Payment_Status)
        VALUES (v_delivery_id, v_calculated_payout, 'Pending');

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Success: Delivery recorded and Payout of ' || v_calculated_payout || ' RWF initialized.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Transaction Failed: Rolling back database changes.');
            RAISE;
    END register_delivery;

END pkg_coffee_mgmt;

/
