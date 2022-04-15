/*
 * Copyright (c) 2009-2010, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.backends.transform;

import java.util.ArrayList;
import java.util.List;

import net.sf.orcc.OrccRuntimeException;
import net.sf.orcc.backends.ir.InstCast;
import net.sf.orcc.backends.ir.IrSpecificFactory;
import net.sf.orcc.ir.Arg;
import net.sf.orcc.ir.ArgByVal;
import net.sf.orcc.ir.Block;
import net.sf.orcc.ir.BlockBasic;
import net.sf.orcc.ir.BlockIf;
import net.sf.orcc.ir.BlockWhile;
import net.sf.orcc.ir.ExprBinary;
import net.sf.orcc.ir.ExprBool;
import net.sf.orcc.ir.ExprFloat;
import net.sf.orcc.ir.ExprInt;
import net.sf.orcc.ir.ExprList;
import net.sf.orcc.ir.ExprString;
import net.sf.orcc.ir.ExprUnary;
import net.sf.orcc.ir.ExprVar;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.InstAssign;
import net.sf.orcc.ir.InstCall;
import net.sf.orcc.ir.InstLoad;
import net.sf.orcc.ir.InstPhi;
import net.sf.orcc.ir.InstReturn;
import net.sf.orcc.ir.InstStore;
import net.sf.orcc.ir.Instruction;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.OpBinary;
import net.sf.orcc.ir.Param;
import net.sf.orcc.ir.Type;
import net.sf.orcc.ir.TypeInt;
import net.sf.orcc.ir.TypeList;
import net.sf.orcc.ir.TypeUint;
import net.sf.orcc.ir.Var;
import net.sf.orcc.ir.util.AbstractIrVisitor;
import net.sf.orcc.ir.util.IrUtil;
import net.sf.orcc.util.util.EcoreHelper;

import org.eclipse.emf.common.util.BasicEList;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.util.EcoreUtil;

/**
 * Add cast in IR in the form of assign instruction where target's type differs
 * from source type.
 * 
 * @author Jerome Goring
 * @author Herve Yviquel
 * @author Matthieu Wipliez
 * 
 */
public class CastAdder extends AbstractIrVisitor<Expression> {

	private final static IrFactory factory = IrFactory.eINSTANCE;
	private final static IrSpecificFactory factorySpec = IrSpecificFactory.eINSTANCE;
	private final boolean castToUnsigned;
	private final boolean createEmptyBlockBasic;
	protected Type parentType;

	/**
	 * Creates a new cast transformation. By default, this constructor creates
	 * an empty BlockBasic for the then or else part of a BlockIf if it is empty
	 * 
	 * @param castToUnsigned
	 *            <code>true</code> if an explicit cast is needed between signed
	 *            and unsigned
	 */
	public CastAdder(boolean castToUnsigned) {
		this(castToUnsigned, true);
	}

	/**
	 * Creates a new cast transformation
	 * 
	 * @param castToUnsigned
	 *            <code>true</code> if an explicit cast is needed between signed
	 *            and unsigned
	 * @param createEmptyBlockBasic
	 *            <code>true</code> if an Empty BlockBasic should be introduced
	 *            when a ifBlock has an empty thenBlock/elseBlock
	 */
	public CastAdder(boolean castToUnsigned, boolean createEmptyBlockBasic) {
		this.castToUnsigned = castToUnsigned;
		this.createEmptyBlockBasic = createEmptyBlockBasic;
	}

	@Override
	public Expression caseBlockIf(BlockIf blockIf) {
		Type oldParentType = parentType;
		parentType = factory.createTypeBool();
		blockIf.setCondition(doSwitch(blockIf.getCondition()));
		doSwitch(blockIf.getThenBlocks());
		doSwitch(blockIf.getElseBlocks());
		doSwitch(blockIf.getJoinBlock());
		parentType = oldParentType;
		return null;
	}

	@Override
	public Expression caseBlockWhile(BlockWhile blockWhile) {
		Type oldParentType = parentType;
		parentType = factory.createTypeBool();
		blockWhile.setCondition(doSwitch(blockWhile.getCondition()));
		doSwitch(blockWhile.getBlocks());
		doSwitch(blockWhile.getJoinBlock());
		parentType = oldParentType;
		return null;
	}

	@Override
	public Expression caseExprBinary(ExprBinary expr) {
		Type oldParentType = parentType;
		Expression e1 = expr.getE1();
		Expression e2 = expr.getE2();
		if (isTypeReducer(expr.getOp())) {
			// FIXME: Probably a better solution
			expr.setType(IrUtil.copy(getBigger(e1.getType(), e2.getType())));
		}
		if (expr.getOp().isComparison()) {
			parentType = getBigger(e1.getType(), e2.getType());
		} else {
			parentType = expr.getType();
		}
		expr.setE1(doSwitch(e1));
		expr.setE2(doSwitch(e2));
		parentType = oldParentType;
		return castExpression(expr);
	}

	@Override
	public Expression caseExprBool(ExprBool expr) {
		return expr;
	}

	@Override
	public Expression caseExprFloat(ExprFloat expr) {
		return expr;
	}

	@Override
	public Expression caseExprInt(ExprInt expr) {
		expr.getType().setSize(parentType.getSizeInBits());
		return expr;
	}

	@Override
	public Expression caseExprList(ExprList expr) {
		castExpressionList(expr.getValue());
		return expr;
	}

	@Override
	public Expression caseExprString(ExprString expr) {
		return expr;
	}

	@Override
	public Expression caseExprUnary(ExprUnary expr) {
		Type oldParentType = parentType;
		parentType = expr.getType();
		expr.setExpr(doSwitch(expr.getExpr()));
		parentType = oldParentType;
		return castExpression(expr);
	}

	@Override
	public Expression caseExprVar(ExprVar expr) {
		return castExpression(expr);
	}

	@Override
	public Expression caseInstAssign(InstAssign assign) {
		Type oldParentType = parentType;
		parentType = assign.getTarget().getVariable().getType();
		Expression newValue = doSwitch(assign.getValue());
		parentType = oldParentType;
		if (newValue != assign.getValue()) {
			// The assignment is useless now, we replace it by the cast
			// instruction
			EList<Instruction> instructions = assign.getBlock()
					.getInstructions();
			InstCast cast = (InstCast) instructions.get(instructions
					.indexOf(assign) - 1);
			cast.setTarget(assign.getTarget());

			IrUtil.delete(assign);
		}
		return null;
	}

	@Override
	public Expression caseInstCall(InstCall call) {
		if (!call.isPrint()) {
			Type oldParentType = parentType;
			Iterable<Expression> expressions = EcoreHelper.getObjects(call,
					Expression.class);
			EList<Expression> oldExpressions = new BasicEList<Expression>();
			for (Expression expr : expressions) {
				oldExpressions.add(expr);
			}

			EList<Expression> newExpressions = new BasicEList<Expression>();
			for (int i = 0; i < oldExpressions.size(); i++) {

				// Check call parameter type coherence
				Param param = call.getProcedure().getParameters().get(i);
				Var variable = param.getVariable();

				parentType = variable.getType();
				Expression expr = oldExpressions.get(i);

				// Check argument if it's not a string
				if (!parentType.isString()) {
					expr = doSwitch(expr);
				}

				newExpressions.add(expr);
			}

			call.getArguments().clear();
			call.getArguments().addAll(factory.createArgsByVal(newExpressions));

			parentType = oldParentType;

			if (call.getTarget() != null) {
				Var target = call.getTarget().getVariable();
				Type returnType = call.getProcedure().getReturnType();
				if (needCast(target.getType(), returnType)) {
					Var castedTarget = procedure.newTempLocalVariable(
							target.getType(), "casted_" + target.getName());
					castedTarget.setIndex(1);

					target.setType(IrUtil.copy(returnType));

					InstCast cast = factorySpec.createInstCast(target,
							castedTarget);

					call.getBlock().add(indexInst + 1, cast);
				}
			}
		} else {
			// Call to print procedure : see if integer parameter cast is
			// necessary (LLVM only)
			EList<Arg> arguments = call.getArguments();
			List<Instruction> castInstrToAdd = new ArrayList<Instruction>();
			List<String> varCasted = new ArrayList<String>();

			// Evaluate every argument of call instruction
			for (Arg callArg : arguments) {

				Expression exprArg = null;
				if (callArg.isByVal()) {
					exprArg = ((ArgByVal) callArg).getValue();

					// TODO: Cleaning
					if (!(exprArg instanceof ExprVar)) {
						/*
						 * Nothing to do, cast is added only for print arguments
						 * which are variables. If a verbose mode is added to
						 * backends in the future, this msg can be used to
						 * prevent useless print calls :
						 * 
						 * String msg =
						 * "[Warn] Parameter of print call is not a String or a Variable : \n\tParameter type : "
						 * + exprArg.getClass().getName() + "\n\tActor : " +
						 * EcoreHelper.getContainerOfType(call,
						 * Actor.class).getName() + "\n\tLine number : " +
						 * call.getLineNumber();
						 */
					} else if ((exprArg.getType().isInt() || exprArg.getType()
							.isUint())
							&& exprArg.getType().getSizeInBits() != 32) {

						Var source = ((ExprVar) exprArg).getUse().getVariable();

						// If variable is used more than one time in call
						// arguments list, we add a cast instruction only for
						// the first occurence
						if (varCasted.contains(source.getName())) {
							continue;
						} else {
							// Add var name to the list of alredy casted vars
							varCasted.add(source.getName());
						}

						// target type must be now on 32 bits
						Type targetType = IrUtil.copy(exprArg.getType());
						if (targetType.isInt()) {
							((TypeInt) targetType).setSize(32);
						} else if (targetType.isUint()) {
							((TypeUint) targetType).setSize(32);
						}

						// target name and type are updated
						Var target = procedure.newTempLocalVariable(targetType, "casted_32_" + source.getName());
						target.setType(targetType);

						// Update variable used in call parameter
						((ExprVar) exprArg).getUse().setVariable(target);

						// Create the concrete cast instruction
						Instruction castInstr = factorySpec.createInstCast(
								source, target);

						// Append cast instruction to tempoary list
						castInstrToAdd.add(castInstr);
					}
				} else {
					throw new OrccRuntimeException("ArgByRef not supported.");
				}
			}
			// Add cast instructions just before call
			BlockBasic debugBlock = call.getBlock();
			for (Instruction instr : castInstrToAdd) {
				debugBlock.add(indexInst++, instr);
			}
		}
		return null;
	}

	@Override
	public Expression caseInstLoad(InstLoad load) {
		// Indexes are not casted...
		Var source = load.getSource().getVariable();
		Var target = load.getTarget().getVariable();

		Type uncastedType;

		if (load.getIndexes().isEmpty()) {
			// Load from a scalar variable
			uncastedType = IrUtil.copy(source.getType());
		} else {
			// Load from an array variable
			uncastedType = IrUtil.copy(((TypeList) source.getType())
					.getInnermostType());
		}

		if (needCast(target.getType(), uncastedType)) {
			Var castedTarget = procedure.newTempLocalVariable(target.getType(),
					"casted_" + target.getName());
			castedTarget.setIndex(1);

			target.setType(uncastedType);

			InstCast cast = factorySpec.createInstCast(target, castedTarget);

			load.getBlock().add(indexInst + 1, cast);
		}
		return null;
	}

	@Override
	public Expression caseInstPhi(InstPhi phi) {
		Type oldParentType = parentType;
		parentType = phi.getTarget().getVariable().getType();
		EList<Expression> values = phi.getValues();

		// FIXME: Need improvment/merging
		Block containingBlock = (Block) phi.getBlock().eContainer();
		Expression value0 = phi.getValues().get(0);
		Expression value1 = phi.getValues().get(1);
		if (containingBlock.isBlockIf()) {
			BlockIf blockIf = (BlockIf) containingBlock;
			if (value0.isExprVar()) {
				if (createEmptyBlockBasic) {
					BlockBasic block0 = factory.createBlockBasic();
					blockIf.getThenBlocks().add(block0);
					values.set(0, castExpression(value0, block0, 0));
				}
			}
			if (value1.isExprVar()) {
				if (createEmptyBlockBasic) {
					BlockBasic block1 = factory.createBlockBasic();
					blockIf.getElseBlocks().add(block1);
					values.set(1, castExpression(value1, block1, 0));
				}
			}
		} else {
			BlockWhile blockWhile = (BlockWhile) containingBlock;
			if (value0.isExprVar()) {
				BlockBasic block = factory.createBlockBasic();
				EcoreHelper.getContainingList(containingBlock).add(indexBlock,
						block);
				indexBlock++;
				values.set(0, castExpression(value0, block, 0));
			}
			if (value1.isExprVar()) {
				BlockBasic block = factory.createBlockBasic();
				blockWhile.getBlocks().add(block);
				values.set(1, castExpression(value1, block, 0));
			}
		}
		parentType = oldParentType;
		return null;
	}

	@Override
	public Expression caseInstReturn(InstReturn returnInstr) {
		Expression expr = returnInstr.getValue();
		if (expr != null) {
			Type oldParentType = parentType;
			parentType = procedure.getReturnType();
			returnInstr.setValue(doSwitch(expr));
			parentType = oldParentType;
		}
		return null;
	}

	@Override
	public Expression caseInstStore(InstStore store) {
		// Indexes are not casted...
		Type oldParentType = parentType;
		if (store.getIndexes().isEmpty()) {
			// Store to a scalar variable
			parentType = store.getTarget().getVariable().getType();
		} else {
			// Store to an array variable
			parentType = ((TypeList) store.getTarget().getVariable().getType())
					.getInnermostType();
		}
		store.setValue(doSwitch(store.getValue()));
		parentType = oldParentType;
		return null;
	}

	private Expression castExpression(Expression expr) {
		if (needCast(expr.getType(), parentType)) {
			Var oldVar;
			if (expr.isExprVar()) {
				oldVar = ((ExprVar) expr).getUse().getVariable();
			} else {
				oldVar = procedure.newTempLocalVariable(
						EcoreUtil.copy(expr.getType()),
						"expr_" + procedure.getName());
				InstAssign assign = factory.createInstAssign(oldVar,
						IrUtil.copy(expr));
				IrUtil.addInstBeforeExpr(expr, assign);
			}

			Var newVar = procedure.newTempLocalVariable(
					EcoreUtil.copy(parentType),
					"castedExpr_" + procedure.getName());
			InstCast cast = factorySpec.createInstCast(oldVar, newVar);
			if (IrUtil.addInstBeforeExpr(expr, cast)) {
				indexInst++;
			}
			IrUtil.delete(expr);
			return factory.createExprVar(newVar);
		}

		return expr;
	}

	private Expression castExpression(Expression expr, BlockBasic block,
			int index) {
		if (needCast(expr.getType(), parentType)) {
			Var oldVar;
			if (expr.isExprVar()) {
				oldVar = ((ExprVar) expr).getUse().getVariable();
			} else {
				oldVar = procedure.newTempLocalVariable(
						EcoreUtil.copy(expr.getType()),
						"expr_" + procedure.getName());
				InstAssign assign = factory.createInstAssign(oldVar,
						IrUtil.copy(expr));
				block.add(index, assign);
				index++;
			}

			Var newVar = procedure.newTempLocalVariable(
					EcoreUtil.copy(parentType),
					"castedExpr_" + procedure.getName());
			InstCast cast = factorySpec.createInstCast(oldVar, newVar);
			block.add(index, cast);
			return factory.createExprVar(newVar);
		}

		return expr;
	}

	private void castExpressionList(EList<Expression> expressions) {
		EList<Expression> oldExpression = new BasicEList<Expression>(
				expressions);
		EList<Expression> newExpressions = new BasicEList<Expression>();
		for (Expression expression : oldExpression) {
			newExpressions.add(doSwitch(expression));
		}
		expressions.clear();
		expressions.addAll(newExpressions);
	}

	private Type getBigger(Type type1, Type type2) {
		if (type1.getSizeInBits() < type2.getSizeInBits()) {
			return type2;
		} else {
			return type1;
		}
	}

	private boolean isTypeReducer(OpBinary op) {
		switch (op) {
		case SHIFT_RIGHT:
		case MOD:
			return true;
		default:
			return false;
		}
	}

	protected boolean needCast(Type type1, Type type2) {
		if (type1.isList() && type2.isList()) {
			TypeList typeList1 = (TypeList) type1;
			TypeList typeList2 = (TypeList) type2;
			List<Integer> dim1 = typeList1.getDimensions();
			List<Integer> dim2 = typeList2.getDimensions();
			for (int i = 0; i < dim1.size() && i < dim2.size(); i++) {
				if (!dim1.get(i).equals(dim2.get(i))) {
					return true;
				}
			}
			return needCast(typeList1.getInnermostType(),
					typeList2.getInnermostType());
		} else {
			return (type1.getSizeInBits() != type2.getSizeInBits())
					|| (castToUnsigned && type1.getClass() != type2.getClass())
					|| (!((type1.isInt() && type2.isUint()) || (type1.isUint() && type2
							.isInt())) && (type1.getClass() != type2.getClass()));
		}
	}

}
