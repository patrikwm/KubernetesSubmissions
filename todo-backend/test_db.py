#!/usr/bin/env python3
"""Simple test script to verify todo-backend database connectivity"""

import asyncio
import os
from uuid import uuid4
from datetime import datetime
import databases

# Database configuration
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", "localhost")
POSTGRES_PORT = int(os.environ.get("POSTGRES_PORT", "5432"))
POSTGRES_DB = os.environ.get("POSTGRES_DB", "postgres")
POSTGRES_USER = os.environ.get("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "example")

DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"

async def test_connection():
    """Test database connection and todo operations"""
    print(f"Testing connection to: {DATABASE_URL.replace(POSTGRES_PASSWORD, '***')}")

    database = databases.Database(DATABASE_URL)

    try:
        await database.connect()
        print("✅ Connected to database successfully")

        # Test basic query
        result = await database.fetch_val("SELECT version()")
        print(f"✅ PostgreSQL version: {result}")

        # Test table creation
        await database.execute("""
            CREATE TABLE IF NOT EXISTS todos_test (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                text VARCHAR(500) NOT NULL,
                done BOOLEAN NOT NULL DEFAULT FALSE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)
        print("✅ Test todos table created successfully")

        # Test insert
        test_id = uuid4()
        test_text = "Test todo item"
        test_time = datetime.utcnow()

        await database.execute(
            "INSERT INTO todos_test (id, text, done, created_at) VALUES (:id, :text, :done, :created_at)",
            {
                "id": test_id,
                "text": test_text,
                "done": False,
                "created_at": test_time
            }
        )
        print("✅ Test todo insert successful")

        # Test select
        result = await database.fetch_one("SELECT * FROM todos_test WHERE id = :id", {"id": test_id})
        print(f"✅ Test select successful: {result['text']}")

        # Test list all
        results = await database.fetch_all("SELECT * FROM todos_test ORDER BY created_at DESC")
        print(f"✅ Test list all successful: Found {len(results)} todos")

        # Test update
        await database.execute(
            "UPDATE todos_test SET done = :done WHERE id = :id",
            {"done": True, "id": test_id}
        )
        print("✅ Test update successful")

        # Verify update
        result = await database.fetch_val("SELECT done FROM todos_test WHERE id = :id", {"id": test_id})
        print(f"✅ Update verification successful: done = {result}")

        # Cleanup
        await database.execute("DROP TABLE todos_test")
        print("✅ Test cleanup successful")

    except Exception as e:
        print(f"❌ Database test failed: {e}")
        return False
    finally:
        await database.disconnect()
        print("✅ Disconnected from database")

    return True

if __name__ == "__main__":
    success = asyncio.run(test_connection())
    if success:
        print("\n🎉 All todo-backend database tests passed!")
    else:
        print("\n💥 Todo-backend database tests failed!")
        exit(1)
