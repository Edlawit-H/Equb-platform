import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { topUpSchema, transactionFilterSchema } from '../validators/wallet.validator.js';
import {
  getWallet,
  topUpWallet,
  getTransactions,
  getTransactionById,
  getTransactionStats,
  getGroupTransactions,
} from '../controllers/transactions.controller.js';

const router = Router();

// All routes require authentication
router.use(protect);

// Wallet
router.get('/wallet', getWallet);
router.post('/top-up', validate(topUpSchema), topUpWallet);

// Stats
router.get('/stats', getTransactionStats);

// Group transactions
router.get('/group/:groupId', getGroupTransactions);

// Transaction list (with filters) and single transaction
router.get('/', validate(transactionFilterSchema), getTransactions);
router.get('/:id', getTransactionById);

export default router;
