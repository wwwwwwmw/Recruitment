import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { getDb } from '../../config/db.js';

function signToken(user){
  const payload = { id: user.id, email: user.email, role: user.role, name: user.full_name };
  const secret = process.env.JWT_SECRET || 'dev';
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
  return jwt.sign(payload, secret, { expiresIn });
}

export async function registerCandidate(req,res,next){
  try{
    const { full_name, email, password } = req.body;
    const hash = await bcrypt.hash(password, 10);
    const { rows } = await getDb().query(
      'INSERT INTO users (full_name, email, password_hash, role) VALUES ($1,$2,$3,$4) RETURNING id, full_name, email, role',
      [full_name, email.toLowerCase(), hash, 'candidate']
    );
    const user = rows[0];
    const token = signToken(user);
    res.status(201).json({ user, token });
  }catch(e){ next(e); }
}

export async function registerByAdmin(req,res,next){
  try{
    const { full_name, email, password, role } = req.body;
    const hash = await bcrypt.hash(password, 10);
    const { rows } = await getDb().query(
      'INSERT INTO users (full_name, email, password_hash, role) VALUES ($1,$2,$3,$4) RETURNING id, full_name, email, role',
      [full_name, email.toLowerCase(), hash, role]
    );
    res.status(201).json(rows[0]);
  }catch(e){ next(e); }
}

export async function login(req,res,next){
  try{
    const { email, password } = req.body;
    const u = await getDb().query('SELECT * FROM users WHERE email=$1', [email.toLowerCase()]);
    const user = u.rows[0];
    if(!user) return res.status(401).json({ message: 'Invalid credentials' });
    const ok = await bcrypt.compare(password, user.password_hash || '');
    if(!ok) return res.status(401).json({ message: 'Invalid credentials' });
    const token = signToken(user);
    res.json({ user: { id:user.id, full_name:user.full_name, email:user.email, role:user.role }, token });
  }catch(e){ next(e); }
}

export async function me(req,res){
  res.json({ user: req.user });
}

export async function logout(req,res){
  // Stateless JWT: client should discard token. Optionally implement denylist.
  res.json({ success: true });
}
